{ lib, config, ... }:

let
  inherit (lib) mkDefault mkIf mkOption types;
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
    sane.gui.enable = mkOption {
      default = false;
      type = types.bool;
      description = ''
        enables config used by any GUI, like display management or select packages.
        the user should prefer to interact with specific GUIs like `sane.gui.sway`
        and let those modules auto-set this flag when necessary.
      '';
    };
  };

  config = mkIf cfg.enable {
    sane.packages.enableGuiPkgs = mkDefault true;

    # preserve backlight brightness across power cycles
    # see `man systemd-backlight`
    sane.persist.sys.plaintext = [ "/var/lib/systemd/backlight" ];
  };
}
