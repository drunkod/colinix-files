{ lib, config, ... }:

with lib;
let
  cfg = config.colinsane.gui.gnome;
in
{
  options = {
    colinsane.gui.gnome.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    # start gnome/gdm on boot
    services.xserver.enable = true;
    services.xserver.desktopManager.gnome.enable = true;
    services.xserver.displayManager.gdm.enable = true;

    # gnome does networking stuff with networkmanager
    networking.useDHCP = false;
    networking.networkmanager.enable = true;
    networking.wireless.enable = lib.mkForce false;
  };
}
