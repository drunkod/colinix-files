{ lib, config, ... }:

with lib;
let
  cfg = config.sane.gui;
in
{
  imports = [
    ./plasma.nix
  ];

  options = {
    # doesn't directly create outputs. consumed by e.g. home-manager.nix module
    sane.gui.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    sane.packages.enableGuiPkgs = lib.mkDefault true;

    # preserve backlight brightness across power cycles
    # see `man systemd-backlight`
    sane.persist.sys.plaintext = [ "/var/lib/systemd/backlight" ];
  };
}
