{ config, pkgs, lib, ... }:
{
  imports = [
    ./../common/all
    #./../common/gnome.nix
    # TODO: remove this phosh.nix file.
    # phosh service support was added to nixpkgs on 2022/05/07: https://github.com/NixOS/nixpkgs/pull/153940
    # it may be possible to import this via <unstable-pkgs>/... path ?
    # or find a more recent nixpkgs which builds with mobile-nixos. that PR indicates people have done so.
    ./phosh.nix
    ./gui-phosh.nix
  ];

  # XXX colin: phosh doesn't work well with passwordless login
  users.users.colin.initialPassword = "147147";

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "aarch64-linux";
    gui = "gnome";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
