{ config, pkgs, mobile-nixos, ... }:
{
  imports = [
    (import "${mobile-nixos}/lib/configuration.nix" {
      device = "pine64-pinephone";
    })
    ./firmware.nix
    ./fs.nix
  ];
  # XXX colin: phosh doesn't work well with passwordless login
  users.users.colin.initialPassword = "147147";

  sane.home-manager.extraPackages = [
    # for web browsers see: https://forum.pine64.org/showthread.php?tid=13669
    pkgs.angelfish  # plasma mobile web browser; broken on phosh (poor wayland support)
    # pkgs.plasma5Packages.index  # file browser
    pkgs.plasma5Packages.konsole  # terminal
    # pkgs.plasma5Packages.pix  # picture viewer
    pkgs.plasma5Packages.kalk  # calculator; broken on phosh
    # pkgs.plasma5Packages.buho  # (plasma mobile?) note application
    pkgs.plasma5Packages.kasts  #  podcast app; works on phosh after setting QT envar
    pkgs.plasma5Packages.koko  # image gallery; broken on phosh
    pkgs.plasma5Packages.kwave  # media player.
    # pkgs.plasma5Packages.neochat  #  matrix client. needs qcoro => no aarch64 support
    # pkgs.plasma5Packages.plasma-dialer  # phone dialer
    # pkgs.plasma5Packages.plasma-mobile  # the whole shebang?
    # pkgs.plasma5Packages.plasma-settings
    pkgs.plasma5Packages.bomber  # arcade game; broken on phosh
    pkgs.plasma5Packages.kapman  # pacman
    pkgs.st  # suckless terminal; broken on phosh
    # pkgs.alacritty  # terminal; crashes phosh
  ];

  sane.nixcache.enable = true;
  sane.impermanence.enable = true;  # XXX experimental
  sane.gui.phosh.enable = true;
  boot.loader.grub.enable = false;
  mobile.bootloader.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  system.stateVersion = "21.11";

  # defined: https://www.freedesktop.org/software/systemd/man/machine-info.html
  # XXX colin: not sure which, if any, software makes use of this
  environment.etc."machine-info".text = ''
    CHASSIS="handset"
  '';

  # enable rotation sensor
  hardware.sensor.iio.enable = true;

  users.groups.feedbackd.gid = config.sane.allocations.feedbackd-gid;
}
