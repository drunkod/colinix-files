{ lib, config, ... }:

with lib;
let
  cfg = config.sane.gui;
in
{
  imports = [
    ./gnome.nix
    ./phosh.nix
    ./plasma.nix
    ./plasma-mobile.nix
    ./sway.nix
  ];

  options = {
    # doesn't directly create outputs. consumed by e.g. home-manager.nix module
    sane.gui.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    sane.home-packages.enableGuiPkgs = lib.mkDefault true;
    # all GUIs use network manager?
    users.users.nm-iodine.uid = config.sane.allocations.nm-iodine-uid;
  };
}
