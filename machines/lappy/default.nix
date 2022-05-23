{ home-manager, config, pkgs, lib, ... }:
{
  imports = [
    ./../common/all
    ./../common/hardware-x86_64.nix
    ./../common/gnome.nix
    ./fs.nix
  ];

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "x86_64-linux";
    gui = "gnome";
  };
}
