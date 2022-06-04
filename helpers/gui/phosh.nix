{ ... }:
{
  # docs: https://github.com/NixOS/nixpkgs/blob/nixos-22.05/nixos/modules/services/x11/desktop-managers/phosh.nix
  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "colin";
    group = "users";
    phocConfig = {
      xwayland = "true";
      # find default outputs by catting /etc/phosh/phoc.ini
      outputs.DSI-1 = {
        scale = 1.5;
      };
    };
  };

  environment.variables = {
    # Qt apps won't always start unless this env var is set
    QT_QPA_PLATFORM = "wayland";
  };
}
