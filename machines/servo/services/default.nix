{ ... }:
{
  imports = [
    ./ddns-he.nix
    ./freshrss.nix
    ./gitea.nix
    ./ipfs.nix
    ./jackett.nix
    ./jellyfin.nix
    ./matrix
    ./munin.nix
    ./navidrome.nix
    ./nginx.nix
    ./pleroma.nix
    ./postfix.nix
    ./postgres.nix
    ./transmission.nix
  ];
}
