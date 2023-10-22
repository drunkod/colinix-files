#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages (ps: [  ])" -p rtl8723cs-wowlan -p util-linux

# yeah, this isn't technically a hook, but the hook infrastructure isn't actually
# restricted to stuff that starts with sxmo_hook_ ...
#
# this script is only called by sxmo_autosuspend, which is small, so if i wanted to
# be more proper i could instead re-implement autosuspend + integrations.
#
# N.B.: if any wake locks are acquired between invocation of this script and the
# rtcwake call below, suspend will fail -- even if those locks are released during
# the same period.
#
# this is because the caller of this script writes /sys/power/wakeup_count, and the
# kernel checks consistency with that during the actual suspend request.
# see: <https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-power>
#
# for this reason, keep this script as short as possible.
#
# common sources of wakelocks (which one may wish to reduce) include:
# - `sxmo_led.sh blink` (every 2s, by default)

import argparse
import logging
import subprocess
import time

logger = logging.getLogger(__name__)

SUSPEND_TIME=300

class Executor:
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run

    def exec(self, cmd: list[str], sudo: bool = False, check: bool = True):
        if sudo:
            cmd = [ 'doas' ] + cmd

        logger.debug(" ".join(cmd))
        if self.dry_run:
            return

        res = subprocess.run(cmd, capture_output=True)
        logger.debug(res.stdout)
        if res.stderr:
            logger.warning(res.stderr)
        if check:
            res.check_returncode()

def main():
    logging.basicConfig()
    logging.getLogger().setLevel(logging.INFO)

    parser = argparse.ArgumentParser(description="suspend the pinephone to RAM, and configure wake triggers to make that appear more transparent")
    parser.add_argument("--dry-run", action='store_true', help="print commands instead of executing them")
    parser.add_argument("--verbose", action='store_true', help="log each command before executing")

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)


    executor = Executor(dry_run=args.dry_run)
    # TODO: don't do this wowlan stuff every single time.
    # - it's costly (can take like 1sec)
    # alternative is to introduce some layer of cache:
    # - do so in a way such that WiFi connection state changes invalidate the cache
    #   - because wowlan enable w/o connection may well behave differently than w/ connection
    # - calculating IP addr from link, and then caching on the args we call our helper with may well suffice
    # and no need to invoke a subprocess here, when it's just python code calling other python code!
    executor.exec(['rtl8723cs-wowlan', 'enable-clean'], sudo=True)
    # wake on ssh
    executor.exec(['rtl8723cs-wowlan', 'tcp', '--dest-port', '22', '--dest-ip', 'SELF'], sudo=True)
    # wake on notification (ntfy/Universal Push)
    # executor.exec(['rtl8723cs-wowlan', 'tcp', '--source-port', '2587', '--dest-ip', 'SELF'], sudo=True)
    # wake if someone doesn't know how to route to us, because that could obstruct the above
    # executor.exec(['rtl8723cs-wowlan', 'arp', '--dest-ip', 'SELF'], sudo=True)
    # specifically wake upon ARP request via the broadcast address.
    # should in theory by covered by the above (TODO: remove this!), but for now hopefully helps wake-on-lan be more reliable?
    executor.exec(['rtl8723cs-wowlan', 'arp', '--dest-ip', 'SELF', '--dest-mac', 'ff:ff:ff:ff:ff:ff'], sudo=True)

    logger.info(f"calling suspend for duration: {SUSPEND_TIME}")

    time_start = time.time()
    # irq_start="$(cat /proc/interrupts | grep 'rtw_wifi_gpio_wakeup' | tr -s ' ' | xargs echo | cut -d' ' -f 2)"
    #
    executor.exec(['rtcwake', '-m', 'mem', '-s', str(SUSPEND_TIME)], check=False)

    # irq_end="$(cat /proc/interrupts | grep 'rtw_wifi_gpio_wakeup' | tr -s ' ' | xargs echo | cut -d' ' -f 2)"
    time_spent = time.time() - time_start

    logger.info(f"suspended for {time_spent:.0f} seconds")

    executor.exec(['sxmo_hook_postwake.sh'], check=False)

if __name__ == '__main__':
    main()
