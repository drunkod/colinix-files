{ home-manager, config, pkgs, ... }:
{
  imports = [
    home-manager.nixosModule
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs; system = "x86_64-linux"; gui = "gnome";
  };
}
