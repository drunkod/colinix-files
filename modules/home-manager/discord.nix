{ config, lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  # TODO: this should only be enabled on gui devices
  # make Discord usable even when client is "outdated"
  home-manager.users.colin.xdg.configFile."discord/settings.json".text = ''
    {
      "SKIP_HOST_UPDATE": true
    }
  '';
}
