{ home-manager, config, pkgs, ... }:
{
  imports = [
    ./../common/homes.nix
    ./../common/users.nix
    ./../common/hardware.nix
    ./fs.nix
  ];
}
