{ lib, config, ... }:

with lib;
let
  cfg = config.colinsane.gui;
in
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

  config = lib.mkIf cfg.enable {
    colinsane.home-manager.enable = true;
  };
}
