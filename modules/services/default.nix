{ ... }:
{
  imports = [
    ./duplicity.nix
    ./kiwix-serve.nix
    ./nixserve.nix
    ./trust-dns.nix
  ];
}
