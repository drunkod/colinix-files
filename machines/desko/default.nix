{ config, pkgs, lib, ... }:
{
  imports = [
    ./../../helpers/universal
    ./../../helpers/hardware-x86_64.nix
    ./../../helpers/gnome.nix
    ./fs.nix
  ];

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "x86_64-linux";
    gui = "gnome";
    extraPackages = [
      pkgs.electrum
    ];
  };
}
