{ config, pkgs, lib, ... }:
{
  imports = [
    ./firmware.nix
    ./fs.nix
    ./kernel.nix
    ./polyfill.nix
  ];

  sane.roles.client = true;
  sane.services.wg-home.enable = true;
  sane.services.wg-home.ip = config.sane.hosts.by-name."moby".wg-home.ip;

  # XXX colin: phosh doesn't work well with passwordless login,
  # so set this more reliable default password should anything go wrong
  users.users.colin.initialPassword = "147147";
  services.getty.autologinUser = "root";  # allows for emergency maintenance?

  sops.secrets.colin-passwd.neededForUsers = true;

  sane.programs.web-browser.config = {
    # compromise impermanence for the sake of usability
    persistCache = "private";
    persistData = "private";

    # i don't do crypto stuff on moby
    addons.ether-metamask.enable = false;
    # addons.sideberry.enable = false;
  };

  sane.user.persist.plaintext = [
    # TODO: make this just generally conditional upon pulse being enabled?
    ".config/pulse"  # persist pulseaudio volume
  ];

  sane.gui.phosh.enable = true;
  # sane.programs.consoleUtils.enableFor.user.colin = false;
  # sane.programs.guiApps.enableFor.user.colin = false;
  sane.programs.sequoia.enableFor.user.colin = false;
  sane.programs.tuiApps.enableFor.user.colin = false;  # visidata, others, don't compile well

  boot.loader.efi.canTouchEfiVariables = false;
  # /boot space is at a premium. default was 20.
  # even 10 can be too much
  # TODO: compress moby kernels!
  boot.loader.generic-extlinux-compatible.configurationLimit = 8;
  # mobile.bootloader.enable = false;
  # mobile.boot.stage-1.enable = false;
  # boot.initrd.systemd.enable = false;
  # boot.initrd.services.swraid.enable = false;  # attempt to fix dm_mod stuff
  # disable proximity sensor.
  # the filtering/calibration is bad that it causes the screen to go fully dark at times.
  boot.blacklistedKernelModules = [ "stk3310" ];

  # without this some GUI apps fail: `DRM_IOCTL_MODE_CREATE_DUMB failed: Cannot allocate memory`
  # this is because they can't allocate enough video ram.
  # the default CMA seems to be 32M.
  # i was running fine with 256MB from 2022/07-ish through 2022/12-ish, but then the phone quit reliably coming back from sleep: maybe a memory leak?
  # `cat /proc/meminfo` to see CmaTotal/CmaFree if interested in tuning this.
  boot.kernelParams = [ "cma=512M" ];

  # mobile-nixos' /lib/firmware includes:
  #   rtl_bt          (bluetooth)
  #   anx7688-fw.bin  (USB-C -> HDMI bridge)
  #   ov5640_af.bin   (camera module)
  # hardware.firmware = [ config.mobile.device.firmware ];
  hardware.firmware = [ pkgs.rtl8723cs-firmware ];

  system.stateVersion = "21.11";

  # defined: https://www.freedesktop.org/software/systemd/man/machine-info.html
  # XXX colin: not sure which, if any, software makes use of this
  environment.etc."machine-info".text = ''
    CHASSIS="handset"
  '';

  # enable rotation sensor
  hardware.sensor.iio.enable = true;

  # inject specialized alsa configs via the environment.
  # specifically, this gets the pinephone headphones & internal earpiece working.
  # see pkgs/patched/alsa-ucm-conf for more info.
  # older code had me also setting `systemd.services.pulseaudio.environment.ALSA_CONFIG_UCM2`,
  # but it seems safe to set this only globally, and not per-service.
  environment.variables.ALSA_CONFIG_UCM2 = "${pkgs.alsa-ucm-conf-sane}/share/alsa/ucm2";

  hardware.opengl.driSupport = true;
}
