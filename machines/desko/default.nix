{ home-manager, config, pkgs, ... }:
{
  imports = [
    ./../common/homes.nix
    ./../common/users.nix
    ./hardware.nix
  ];
}
