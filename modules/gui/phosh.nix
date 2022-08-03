{ lib, config, ... }:

with lib;
let
  cfg = config.sane.gui.phosh;
in
{
  options = {
    sane.gui.phosh.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    sane.gui.enable = true;

    users.users.avahi.uid = config.sane.allocations.avahi-uid;
    users.users.colord.uid = config.sane.allocations.colord-uid;
    users.users.geoclue.uid = config.sane.allocations.geoclue-uid;
    users.users.rtkit.uid = config.sane.allocations.rtkit-uid;
    users.groups.avahi.gid = config.sane.allocations.avahi-gid;
    users.groups.colord.gid = config.sane.allocations.colord-gid;
    users.groups.geoclue.gid = config.sane.allocations.geoclue-gid;
    users.groups.rtkit.gid = config.sane.allocations.rtkit-gid;

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

    # XXX: phosh enables networkmanager by default; can probably disable these lines
    networking.useDHCP = false;
    networking.networkmanager.enable = true;
    networking.wireless.enable = lib.mkForce false;

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
