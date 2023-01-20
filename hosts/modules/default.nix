{ ... }:

{
  imports = [
    ./derived-secrets.nix
    ./hardware
    ./hosts.nix
    ./roles
    ./wg-home.nix
  ];
}
