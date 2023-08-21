#!/usr/bin/env python
#!nix-shell -i python -p "python3.withPackages (ps: [  ])"
#!/usr/bin/env nix-shell

# it's possible to interact with the AT device using just python builtin `file`:
# - `wr = io.open(DEVICE, 'wb', 0)` to create an unbuffered writer
# - `wr.write(b'ATI\r')`
# - `rd = io.open(DEVICE, 'rb', 0)`
# - `rd.read(1024)`  to read at most 1024 bytes
#
# the issue is that the read call has to be started before the write call.
# i.e. if there's no reader when the modem replies, the modem's response gets thrown away.
#
# /dev/ttyUSB2 is a character device
# - as shown by `pathlib.Path('/dev/ttyUSB2').is_char_device()`
# - that means `fcntl(fd, F_SETPIPE_SZ, ...)` can't be used to buffer it
#
# the driver for /dev/ttyUSB2 lives in megi's kernel tree:
# - at drivers/misc/modem-power.c
# - couple entry points for receiving messages:
#   - mpwr_eg25_receive_msg is referenced by the mpwr_variant
#     - path of mpwr_dev->variant->recv_msg
#     - probably not directly callable externally
#   - mpwr_serdev_receive_buf is referenced by mpwr_serdev_probe
#     - passed into serdev_device_set_client_ops
#     - probably the externally visible method then
# - mpwr_eg25_receive_msg:
#   - calls mpwr->variant->recv_msg
#   - kfifo_in(&mpwr->kfifo, msg, msg_len);
#   - kfifo_in(&mpwr->kfifo, "\n", 1);
#   - wake_up(&mpwr->wait);
#
# - mpwr_serdev_receive_buf:
#   - copies `msg` onto `mpwr->rcvbuf`
#   - wraps `mpwr_serdev_receive_msg` in a loop
# - mpwr_serdev_receive_msg:
#   - has a valid `msg` char* when it's called (i.e., the data has _already_ been lifted off the serial port?)
#   - copies the msg to `mpwr->msg`, but skips OK and ERROR messages
# ^ these two seem to be not polling the device, but rather parsing the messages the dev has yielded
#   and returning only as many characters as the user asked for
#
# Ok! so linux character device calls `mpwr_serdev_receive_msg` when the modem has data
# - modem-power.c accumulates the characters into a buffer, and parses things like `OK` and `ERROR`.
# - only full messages are pushed into mpwr_eg25_receive_msg, where they're placed into the kfifo.
#   - note, a side effect of this is that \r\n is translated to just `\n`? or becomes `\r\n\n`?
#
# - mpwr_dev->kfifo is 4096B:
#   - DECLARE_KFIFO(kfifo, unsigned char, 4096);
#   - the kfifo isn't exposed to any external code
#
# - struct file_operations mpwr_fops
#   - mpwr_read ; also _open, _release, _poll ; no seek
#   - made user-visible during probe: `cdev_init(&mpwr->cdev, &mpwr_fops);`
#   - mpwr_read:
#     - wait_event_interruptible(mpwr->wait, !kfifo_is_empty(&mpwr->kfifo))
#     - kfifo_to_user(&mpwr->kfifo, buf, len, &copied);
#   - then... the driver should still accumulate into the kfifo even without an outstanding read,
#     - and a subsequent read should grab from the fifo.
#       - maybe a logic error with that `wait_event_interruptible`? or just another process is racing against me!
#
# actually, `lsof /dev/ttyUSB2` shows that ModemManager has it open.
# - we're racing for data against ModemManager
# i need to be using `mmcli --command` instead
# - how to put ModemManager into "debug" mode?
#
# eg25 modem/GPS docs:
# [GNSS-AP-Note]: https://wiki.pine64.org/images/0/09/Quectel_EC2x%26EG9x%26EG2x-G%26EM05_Series_GNSS_Application_Note_V1.3.pdf
#
# Global Navigation Satellite Systems:
# - GPS (US)
# - GLONASS (RU)
# - Galileo (EU)
# - BeiDou (CN)
#
# eg25-manager docs suggest AGPS doesn't work for galileo?
# - they enable only GPS and GLONASS


import argparse
import datetime
import logging
import subprocess
import sys
import time

POWER_ENDPOINT = "/sys/class/modem-power/modem-power/device/powered"
# GNSS-AP-Note 1.4:
# also at xtrapath5 and xtrapath6 subdomains
AGPS_DATA_URI_BASE = "https://xtrapath4.izatcloud.net"

class AgpsDataVariant:
    # GNSS-AP-Note 1.4:
    gps_glonass = "xtra2.bin"
    gps_glonass_beidou = "xtra3grc.bin"
    # N.B.: not supported by all Quectel modems
    # on stock Pinephone, ModemManager gives "LOC service: general failure"
    gps_glonass_beidou_galileo = "xtra3grcej.bin"

logger = logging.getLogger(__name__)

def destructive(fn: callable = None, return_ = None):
    """ decorate `fn` so that it becomes a no-op when --dry-run is active """
    def wrapped(self, *args, **kwargs):
        if self.dry_run:
            fmt_args = ", ".join(
                [repr(a) for a in args] +
                [f"{k}={v}" for k,v in kwargs.items()]
            )
            logger.info(f"[dry run] {fn.__name__}({fmt_args})")
            return return_
        else:
            return fn(self, *args, **kwargs)
    if fn:
        return wrapped
    else:
        return lambda fn: destructive(fn, return_=return_)

def log_scope(at_enter: str, at_exit: str):
    """ decorate a function so that it logs at start and end """
    def decorator(fn: callable):
        def wrapped(*args, **kwargs):
            logger.info(at_enter)
            ret = fn(*args, **kwargs)
            logger.info(at_exit)
            return ret
        return wrapped
    return decorator

class Executor:
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run

    @destructive
    def write_file(self, path: str, data: bytes) -> None:
        logger.debug(f"echo {data!r} > {path}")
        with open(path, 'wb') as f:
            f.write(data)

    @destructive(return_=b'')
    def exec(self, cmd: list[str], check: bool = True) -> bytes:
        logger.debug(" ".join(cmd))
        res = subprocess.run(cmd, capture_output=True)
        logger.debug(res.stdout)
        if res.stderr:
            logger.warning(res.stderr)
        if check:
            res.check_returncode()
        return res.stdout

class GNSSConfig:
    # GNSS-AP-Note 2.2.7
    #   Supported GNSS constellations. GPS is always ON
    #   0 GLONASS OFF/BeiDou OFF/Galileo OFF
    #   1 GLONASS ON/BeiDou ON/Galileo ON
    #   2 GLONASS ON/BeiDou ON/Galileo OFF
    #   3 GLONASS ON/BeiDou OFF/Galileo ON
    #   4 GLONASS ON/BeiDou OFF/Galileo OFF
    #   5 GLONASS OFF/BeiDou ON/Galileo ON
    #   6 GLONASS OFF/BeiDou OFF/Galileo ON
    #   7 GLONASS OFF/BeiDou ON/Galileo OFF
    gps = "0"
    gps_glonass_beidou_galileo = "1"
    gps_glonass_beidou = "2"
    gps_glonass_galilego = "3"
    gps_glonass = "4"
    gps_beidou_galileo = "5"
    gps_galileo = "6"
    gps_beidou = "7"

class ODPControl:
    # GNSS-AP-Note 2.2.8
    #   0 Disable ODP
    #   1 Low power mode
    #   2 Ready mode
    #
    # ODP = "On-Demand Positioning"
    # Low power mode:
    # - low-frequency background GNSS tracking session
    # - adjusts interval between 10m (when signal is good) - 60m (when signal is bad)
    # Ready mode:
    # - 1 Hz positioning
    # - keeps GNSS ready so that when application demands position it's immediately ready
    # - automatically stops positioning after 60s??
    disable = "0"
    lower_power_mode = "1"
    ready_mode = "2"

class DPOEnable:
    # GNSS-AP-Note 2.2.9
    #   0 Disable DPO
    #   1 Enable the DPO with dynamic duty cycle
    #
    # DPO = "Dynamic Power Optimization"
    # automatically shuts off radio under certain conditions
    # more info: <https://sixfab.com/wp-content/uploads/2018/09/Quectel_UC20_GNSS_AT_Commands_Manual_V1.1.pdf> 1.4.1
    disable = "0"
    enable = "1"

class GPSNMEAType:
    # GNSS-AP-Note 2.2.3
    #   Output type of GPS NMEA sentences in ORed.
    disable = 0
    gpgga = 1
    gprmc = 2
    gpgsv = 4
    gpgsa = 8
    gpvtg = 16
    all = 31

class GlonassNmeaType:
    # GNSS-AP-Note 2.2.4
    #   Configure output type of GLONASS NMEA sentences in ORed
    disable = 0
    glgsv = 1
    gngsa = 2
    gngns = 4
    all = 7

class GalileoNmeaType:
    # GNSS-AP-Note 2.2.5
    disable = 0
    gagsv = 1
    all = 1

class BeiDouNmeaType:
    # GNSS-AP-Note 2.2.6
    disable = 0
    pqgsa = 1
    pqgsv = 2
    all = 3

class AutoGps:
    # GNSS-AP-Note 2.2.12
    #    Enable/disable GNSS to run automatically after the module is powered on.
    disable = "0"
    enable = "1"

class Sequencer:
    POWER_ENDPOINT = POWER_ENDPOINT
    AGPS_DATA_URI_BASE = AGPS_DATA_URI_BASE
    def __init__(self, executor: Executor):
        self.executor = executor

    def _mmcli(self, args: list[str], check: bool = True) -> str:
        return self.executor.exec(
            ["mmcli", "--modem", "any"] + args,
            check=check
        ).decode('utf-8')

    def _try_mmcli(self, args: list[str]) -> str:
        try:
            return self._mmcli(args)
        except subprocess.CalledProcessError:
            return None

    def _at_cmd(self, cmd: str, check: bool = True) -> str:
        # this returns the mmcli output, which looks like:
        # response: 'blah'
        # i.e., quoted, and with a `response: ` prefix
        return self._mmcli([f"--command=+{cmd}"], check=check)

    def _at_structured_cmd(self, cmd: str, subcmd: str | None = None, value: str | None = None, check: bool = True) -> str:
        if not subcmd and not value:
            return self._at_cmd(cmd, check=check)
        elif not subcmd and value:
            return self._at_cmd(f"{cmd}={value}", check=check)
        elif subcmd and not value:
            return self._at_cmd(f"{cmd}=\"{subcmd}\"", check=check)
        else:
            return self._at_cmd(f"{cmd}=\"{subcmd}\",{value}", check=check)

    def _at_gnssconfig(self, cfg: GNSSConfig) -> str:
        return self._at_structured_cmd("QGPSCFG", "gnssconfig", cfg)

    def _at_odpcontrol(self, control: ODPControl) -> str:
        return self._at_structured_cmd("QGPSCFG", "odpcontrol", control)

    def _at_dpoenable(self, enable: DPOEnable) -> str:
        return self._at_structured_cmd("QGPSCFG", "dpoenable", enable)

    def _at_gpsnmeatype(self, ty: GPSNMEAType) -> str:
        return self._at_structured_cmd("QGPSCFG", "gpsnmeatype", str(ty))

    def _at_glonassnmeatype(self, ty: GlonassNmeaType) -> str:
        return self._at_structured_cmd("QGPSCFG", "glonassnmeatype", str(ty))

    def _at_galileonmeatype(self, ty: GalileoNmeaType) -> str:
        return self._at_structured_cmd("QGPSCFG", "galileonmeatype", str(ty))

    def _at_beidounmeatype(self, ty: BeiDouNmeaType) -> str:
        self._at_structured_cmd("QGPSCFG", "beidounmeatype", str(ty))

    def _at_autogps(self, enable: AutoGps) -> str:
        return self._at_structured_cmd("QGPSCFG", "autogps", enable)

    def _get_assistance_data(self, variant: AgpsDataVariant) -> str:
        self.executor.exec(["curl", f"{self.AGPS_DATA_URI_BASE}/{variant}", "-o", variant])
        return variant

    @log_scope("powering modem...", "modem powered")
    def power_on(self) -> None:
        self.executor.write_file(self.POWER_ENDPOINT, b'1')
        while self._try_mmcli([]) is None:
            logger.info("modem hasn't appeared: sleeping for 1s")
            time.sleep(1)  # wait for modem to appear

    def at_check(self) -> None:
        """ sanity check that the modem is listening for AT commands and responding reasonably """
        hw = self._at_cmd("QGMR")
        assert 'EG25GGBR07A08M2G' in hw or self.executor.dry_run, hw

    def dump_debug_info(self) -> None:
        logger.debug('checking if AGPS is enabled (1) or not (0)')
        self._at_structured_cmd('QGPSXTRA?')
        # see if the GPS assistance data is still within valid range
        logger.debug('QGPSXTRADATA: <valid_duration_minutes>,<start_time_of_agps_data>')
        self._at_structured_cmd('QGPSXTRADATA?')
        logger.debug('checking what time the modem last synchronized with the network')
        self._at_structured_cmd('QLTS')
        logger.debug('checking what time the modem thinks it is (extrapolated from sync)')
        self._at_structured_cmd('QLTS', value=1)
        logger.debug('checking what time the modem thinks it is (from RTC)')
        self._at_structured_cmd('CCLK?')
        logger.debug('checking if nmea GPS source is enabled')
        self._at_structured_cmd('QGPSCFG', 'nmeasrc')
        logger.debug('checking if GPS is enabled (1) or not (0)')
        self._at_structured_cmd('QGPS?')
        logger.debug('checking if GPS has a fix. Error 516 if not')
        self._at_structured_cmd('QGPSLOC', value='0', check=False)
        logger.debug('dumping AGPS positioning mode bitfield')
        self._at_structured_cmd('QGPSCFG', 'agpsposmode')

    @log_scope("configuring audio...", "audio configured")
    def config_audio(self) -> None:
        # cribbed from eg25-manager; i don't understand these
        # QDAI call shouldn't be necessary if using Megi's FW:
        # - <https://xnux.eu/devices/feature/modem-pp.html>
        self._at_structured_cmd("QDAI", value="1,1,0,1,0,0,1,1")
        # RI signaling using physical RI pin
        self._at_structured_cmd("QCFG", "risignaltype", "\"physical\"")
        # Enable VoLTE support
        self._at_structured_cmd("QCFG", "ims", "1")
        # Enable APREADY for PP 1.2
        self._at_structured_cmd("QCFG", "apready", "1,0,500")

    @log_scope("configuring urc...", "urc configured")
    def config_urc(self) -> None:
        # cribbed from eg25-manager; i don't even know what URC is
        # URC configuration for PP 1.2 (APREADY pin connected):
        #   * RING URC: normal pulse length
        #   * Incoming SMS URC: default pulse length
        #   * Other URC: default length
        #   * Report URCs on all ports (serial and USB) for FOSS firmware
        #   * Reporting of URCs without any delay
        #   * Configure URC pin to UART Ring Indicator
        self._at_structured_cmd("QCFG", "urc/ri/ring", "\"pulse\",120,1000,5000,\"off\",1")
        self._at_structured_cmd("QCFG", "urc/ri/smsincoming", "\"pulse\",120,1")
        self._at_structured_cmd("QCFG", "urc/ri/other", "\"off\",1,1")
        self._at_structured_cmd("QCFG", "urc/delay", "0")
        self._at_structured_cmd("QCFG", "urc/cache", "0")
        self._at_structured_cmd("QCFG", "urc/ri/pin", "uart_ri")
        self._at_structured_cmd("QURCCFG", "urcport", "\"all\"")

    @log_scope("configuring gps...", "gps configured")
    def config_gps(self) -> None:
        # set modem to use UTC time instead of local time.
        # modemmanager sends CTZU=3 during init and that causes `AT+CCLK?` to return a timestamp that's off by 600+ days
        # see: <https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/issues/360>
        self._at_structured_cmd("CTZU", value="1")

        # disable GNSS, because it's only configurable while offline
        self._at_structured_cmd("QGPSEND", check=False)
        # self._at_structured_cmd("QGPS", value="0")

        # XXX: ModemManager plugin sets QGPSXTRA=1
        # self._at_structured_cmd("QGPSXTRA", value="1")

        # now = datetime.datetime.now().strftime('%Y/%m/%d,%H:%M:%S')  # UTC
        # self._at_structured_cmd("QGPSXTRATIME", value=f"0,\"{now}\"")
        locdata = self._get_assistance_data(AgpsDataVariant.gps_glonass_beidou)
        self._mmcli([f"--location-inject-assistance-data={locdata}"])
        self._at_gnssconfig(GNSSConfig.gps_glonass_beidou_galileo)
        self._at_odpcontrol(ODPControl.disable)
        self._at_dpoenable(DPOEnable.disable)  # N.B.: eg25-manager uses `DPOEnable.enable`
        self._at_gpsnmeatype(GPSNMEAType.all)
        self._at_glonassnmeatype(GlonassNmeaType.all)
        self._at_galileonmeatype(GalileoNmeaType.all)
        self._at_beidounmeatype(BeiDouNmeaType.all)
        self._at_autogps(AutoGps.disable)  #< don't start GPS on modem boot
        # configure so GPS output is readable via /dev/ttyUSB1
        # self._mmcli(["--location-enable-gps-unmanaged"])
        self._at_structured_cmd("QGPS", value="1,255,1000,0,1")

    @log_scope("configuring powersave...", "powersave configured")
    def config_powersave(self) -> None:
        # Allow sleeping for power saving
        self._at_structured_cmd("QSCLK", value="1")
        # Disable fast poweroff for stability
        self._at_structured_cmd("QCFG", "fast/poweroff", "0")
        # Configure sleep and wake up pin levels to active low
        self._at_structured_cmd("QCFG", "sleepind/level", "0")
        self._at_structured_cmd("QCFG", "wakeupin/level", "0,0")
        # Do not enter RAMDUMP mode, auto-reset instead
        self._at_structured_cmd("QCFG", "ApRstLevel", "1")
        self._at_structured_cmd("QCFG", "ModemRstLevel", "1")


def main():
    logging.basicConfig()
    logging.getLogger().setLevel(logging.INFO)

    parser = argparse.ArgumentParser(description="initialize the eg25 Pinephone modem for GPS tracking")
    parser.add_argument("--dry-run", action='store_true', help="print commands instead of executing them")
    parser.add_argument("--verbose", action='store_true', help="log each command before executing")
    parser.add_argument('--dump-debug-info', action='store_true', help="don't initialize anything, just dump debugging data")

    args = parser.parse_args()
    if args.verbose or args.dump_debug_info:
        logging.getLogger().setLevel(logging.DEBUG)

    executor = Executor(args.dry_run)
    sequencer = Sequencer(executor)

    if not args.dump_debug_info:
        sequencer.power_on()
        sequencer.at_check()
        # sequencer.config_audio()
        # sequencer.config_urc()
        sequencer.config_gps()
        # sequencer.config_powersave()

    if args.verbose or args.dump_debug_info:
        sequencer.dump_debug_info()

if __name__ == '__main__':
    main()
