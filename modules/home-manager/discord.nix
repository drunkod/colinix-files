{ config, lib, ... }:

# XXX: this doesn't work when discord files are persisted to ~/private
# TODO: is there some env var for this? or i could wrap the Discord binary to create this on launch
lib.mkIf false
# lib.mkIf config.sane.home-manager.enable
{
  # TODO: this should only be enabled on gui devices
  # make Discord usable even when client is "outdated"
  home-manager.users.colin.xdg.configFile."discord/settings.json".text = ''
    {
      "SKIP_HOST_UPDATE": true
    }
  '';
}
