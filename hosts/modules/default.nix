{ ... }:

{
  imports = [
    ./derived-secrets.nix
    ./hardware
    ./hostnames.nix
    ./hosts.nix
    ./roles
    ./wg-home.nix
  ];
}
