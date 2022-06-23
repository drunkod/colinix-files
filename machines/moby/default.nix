{ pkgs, mobile-nixos, ... }:
{
  imports = [
    (import "${mobile-nixos}/lib/configuration.nix" {
      device = "pine64-pinephone";
    })
    ./fs.nix
  ];
  # XXX colin: phosh doesn't work well with passwordless login
  users.users.colin.initialPassword = "147147";

  colinsane.home-manager.extraPackages = [
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
    pkgs.w3m  # text-based web browser; works!
    pkgs.st  # suckless terminal; broken on phosh
    # pkgs.alacritty  # terminal; crashes phosh
  ];

  colinsane.gui.phosh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  # defined: https://www.freedesktop.org/software/systemd/man/machine-info.html
  # XXX colin: not sure which, if any, software makes use of this
  environment.etc."machine-info".text = ''
    CHASSIS="handset"
  '';

  # enable rotation sensor
  hardware.sensor.iio.enable = true;
}
