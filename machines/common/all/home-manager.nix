{ home-manager, config, pkgs, ... }:
{
  imports = [
    home-manager.nixosModule
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
