{ lib, ... }:

with lib;
{
  imports = [
    ./gnome.nix
    ./phosh.nix
    ./plasma-mobile.nix
    ./sway.nix
  ];

  options = {
    # doesn't directly create outputs. consumed by e.g. home-manager.nix module
    colinsane.gui.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };
}
