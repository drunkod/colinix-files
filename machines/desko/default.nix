{ config, pkgs, lib, ... }:
{
  imports = [
    ./../../helpers/universal
    ./../../helpers/hardware-x86_64.nix
    # ./../../helpers/gui/gnome.nix
    #./../../helpers/gui/i3.nix
    ./../../helpers/gui/sway.nix
    ./fs.nix
  ];

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "x86_64-linux";
    # gui = "gnome";
    # gui = "i3";
    gui = "sway";
    extraPackages = [
      pkgs.electrum
    ];
  };

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
