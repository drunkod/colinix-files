{ config, pkgs, lib, mobile-nixos, ... }:
{
  imports = [
    # (import "${mobile-nixos}/lib/configuration.nix" {
    #   device = "pine64-pinephone";
    # })
    ./firmware.nix
    ./fs.nix
    ./kernel.nix
  ];
  # XXX colin: phosh doesn't work well with passwordless login
  users.users.colin.initialPassword = "147147";
  services.getty.autologinUser = "root";  # allows for emergency maintenance?

  # usability compromises
  sane.impermanence.home-dirs = [
    ".librewolf"
  ];

  # sane.home-manager.extraPackages = [
  #   # for web browsers see: https://forum.pine64.org/showthread.php?tid=13669
  #   pkgs.angelfish  # plasma mobile web browser; broken on phosh (poor wayland support)
  #   # pkgs.plasma5Packages.index  # file browser
  #   pkgs.plasma5Packages.konsole  # terminal
  #   # pkgs.plasma5Packages.pix  # picture viewer
  #   pkgs.plasma5Packages.kalk  # calculator; broken on phosh
  #   # pkgs.plasma5Packages.buho  # (plasma mobile?) note application
  #   pkgs.plasma5Packages.kasts  #  podcast app; works on phosh after setting QT envar
  #   pkgs.plasma5Packages.koko  # image gallery; broken on phosh
  #   pkgs.plasma5Packages.kwave  # media player.
  #   # pkgs.plasma5Packages.neochat  #  matrix client. needs qcoro => no aarch64 support
  #   # pkgs.plasma5Packages.plasma-dialer  # phone dialer
  #   # pkgs.plasma5Packages.plasma-mobile  # the whole shebang?
  #   # pkgs.plasma5Packages.plasma-settings
  #   pkgs.plasma5Packages.bomber  # arcade game; broken on phosh
  #   pkgs.plasma5Packages.kapman  # pacman
  #   pkgs.st  # suckless terminal; broken on phosh
  #   # pkgs.alacritty  # terminal; crashes phosh
  # ];
  # sane.home-packages.enableGuiPkgs = false;  # XXX faster builds/imaging for debugging
  sane.home-manager.extraPackages = [
    pkgs.plasma5Packages.konsole  # terminal
  ];

  sane.nixcache.enable = true;
  sane.impermanence.enable = true;
  sane.gui.phosh.enable = true;

  boot.loader.efi.canTouchEfiVariables = false;
  # /boot space is at a premium. default was 20.
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;
  # mobile.bootloader.enable = false;
  # mobile.boot.stage-1.enable = false;
  # boot.initrd.systemd.enable = false;
  # boot.initrd.services.swraid.enable = false;  # attempt to fix dm_mod stuff

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

  users.groups.feedbackd.gid = config.sane.allocations.feedbackd-gid;

  hardware.opengl.driSupport = true;
}
