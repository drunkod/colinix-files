{ ... }:

{
  imports = [
    ./fs.nix
    ./hardware.nix
    ./net.nix
    ./users.nix
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
}

