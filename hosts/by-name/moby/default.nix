{ config, pkgs, lib, ... }:
{
  imports = [
    ./firmware.nix
    ./fs.nix
    ./kernel.nix
  ];

  sane.roles.client = true;
  sane.services.wg-home.enable = true;
  sane.services.wg-home.ip = config.sane.hosts.by-name."moby".wg-home.ip;

  # cross-compiled documentation is *slow*.
  # no obvious way to natively compile docs (2022/09/29).
  # entrypoint is nixos/modules/misc/documentation.nix
  # doc building happens in nixos/doc/manual/default.nix
  # TODO: we could *maybe* inject pkgs.buildPackages.xyz = cross.buildPackages.xyz?
  documentation.nixos.enable = false;

  # XXX colin: phosh doesn't work well with passwordless login,
  # so set this more reliable default password should anything go wrong
  users.users.colin.initialPassword = "147147";
  services.getty.autologinUser = "root";  # allows for emergency maintenance?

  sops.secrets.colin-passwd = {
    sopsFile = ../../../secrets/moby.yaml;
    neededForUsers = true;
  };

  # usability compromises
  sane.web-browser.persistCache = "private";
  sane.web-browser.persistData = "private";
  sane.persist.home.plaintext = [
    ".config/pulse"  # persist pulseaudio volume
  ];

  # sane.packages.enableGuiPkgs = false;  # XXX faster builds/imaging for debugging
  sane.packages.extraUserPkgs = [
    pkgs.plasma5Packages.konsole  # terminal
  ];

  sane.nixcache.enable = true;
  sane.persist.enable = true;
  sane.gui.phosh.enable = true;

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
  # the default CMA seems to be 32M. we could probably get by with as little as 64M, and safely with 128M.
  # `cat /proc/meminfo` to see CmaTotal/CmaFree if interested in tuning this.
  boot.kernelParams = [ "cma=256M" ];

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

  # from https://gitlab.manjaro.org/manjaro-arm/packages/community/phosh/alsa-ucm-pinephone
  # mobile-nixos does this same thing, with *slightly different settings*.
  # i trust manjaro more because the guy maintaining that is actively trying to upstream into alsa-ucm-conf.
  # an alternative may be to build a custom alsa with the PinePhone config patch applied:
  # - <https://github.com/alsa-project/alsa-ucm-conf/pull/134>
  # that would make this be not device-specific
  environment.variables.ALSA_CONFIG_UCM2 = "${./ucm2}";
  systemd.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = "${./ucm2}";

  hardware.opengl.driSupport = true;
}
