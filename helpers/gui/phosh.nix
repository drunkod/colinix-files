{ ... }:
{
  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "colin";
    group = "users";
    # phocConfig = {
    #   # find default outputs by catting /etc/phosh/phoc.ini
    #   outputs.DSI-1 = {
    #     scale = 1.50;  # nixpkgs doesn't allow floats for this value
    #   };
    # };
    phocConfig = ''
    [core]
    xwayland = false
    [output:DSI-1]


    scale = 1.5


    [cursor]
    theme = default
    '';
  };

  environment.variables = {
    # Qt apps won't always start unless this env var is set
    QT_QPA_PLATFORM = "wayland";
  };
}
