{ ... }:
{
  imports = [
    ./ddns-he.nix
    ./gitea.nix
    ./ipfs.nix
    ./jackett.nix
    ./jellyfin.nix
    ./matrix
    ./navidrome.nix
    ./nginx.nix
    ./pleroma.nix
    ./postfix.nix
    ./postgres.nix
    ./transmission.nix
  ];
}
