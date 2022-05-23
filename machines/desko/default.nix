{ home-manager, config, pkgs, lib, ... }:
{
  imports = [
    ./../common/home-manager.nix
    ./../common/users.nix
    ./../common/hardware.nix
    ./../common/gui.nix
    ./fs.nix
  ];

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "x86_64-linux";
    gui = "gnome";
  };
}
