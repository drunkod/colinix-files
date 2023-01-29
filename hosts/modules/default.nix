{ ... }:

{
  imports = [
    ./derived-secrets.nix
    ./gui
    ./hardware
    ./hostnames.nix
    ./hosts.nix
    ./roles
    ./wg-home.nix
  ];
}
