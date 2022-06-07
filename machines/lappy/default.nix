{ pkgs, lib, ... }:
{
  imports = [
    ./../../helpers/universal
    ./../../helpers/hardware-x86_64.nix
    # ./../../helpers/gui/gnome.nix
    ./fs.nix
  ];

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs lib;
    system = "x86_64-linux";
    # gui = "gnome";
    gui = "sway";
  };

  colinsane.gui.sway.enable = true;

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
