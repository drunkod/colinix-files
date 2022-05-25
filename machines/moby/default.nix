{ config, pkgs, lib, ... }:
{
  imports = [
    ./../common/all
    ./gui-phosh.nix
  ];

  # XXX colin: phosh doesn't work well with passwordless login
  users.users.colin.initialPassword = "147147";

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "aarch64-linux";
    gui = "phosh";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
