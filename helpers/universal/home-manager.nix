{ home-manager, ... }:
{
  imports = [
    home-manager.nixosModule
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
