{ ... }:

{
  imports = [
    ./derived-secrets.nix
    ./gui
    ./hardware
    ./hostnames.nix
    ./hosts.nix
    ./roles
    ./services
    ./wg-home.nix
  ];
}
