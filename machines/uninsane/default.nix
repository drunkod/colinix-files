{ pkgs, lib, ... }:

{
  imports = [
    ./../common/all
    ./fs.nix
    ./hardware.nix
    ./net.nix
    ./users.nix
    ./services/duplicity.nix
    ./services/gitea.nix
    ./services/jackett.nix
    ./services/jellyfin.nix
    ./services/matrix.nix
    ./services/nginx.nix
    ./services/pleroma.nix
    ./services/postfix.nix
    ./services/postgres.nix
    ./services/transmission.nix
  ];

  home-manager.users.colin = import ../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "aarch64-linux";
    gui = null;
    extraPackages = [ pkgs.matrix-synapse ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

