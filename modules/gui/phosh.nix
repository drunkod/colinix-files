{ lib, config, ... }:

with lib;
let
  cfg = config.colinsane.gui.phosh;
in
{
  options = {
    colinsane.gui.phosh.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    colinsane.gui.enable = true;
    # docs: https://github.com/NixOS/nixpkgs/blob/nixos-22.05/nixos/modules/services/x11/desktop-managers/phosh.nix
    services.xserver.desktopManager.phosh = {
      enable = true;
      user = "colin";
      group = "users";
      phocConfig = {
        # xwayland = "true";
        # find default outputs by catting /etc/phosh/phoc.ini
        outputs.DSI-1 = {
          scale = 1.5;
        };
      };
    };

    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;

    environment.variables = {
      # Qt apps won't always start unless this env var is set
      QT_QPA_PLATFORM = "wayland";
      # electron apps (e.g. Element) should use the wayland backend
      # toggle this to have electron apps (e.g. Element) use the wayland backend.
      # phocConfig.xwayland should be disabled if you do this
      NIXOS_OZONE_WL = "1";
    };
  };
}
