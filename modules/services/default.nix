{ ... }:
{
  imports = [
    ./duplicity.nix
    ./dyn-dns.nix
    ./kiwix-serve.nix
    ./nixserve.nix
    ./trust-dns.nix
  ];
}
