{ config, lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  # TODO: this should only be shipped on gui platforms
  sops.secrets."sublime_music_config" = {
    owner = config.users.users.colin.name;
    sopsFile = ../../secrets/universal/sublime_music_config.json.bin;
    format = "binary";
  };
  home-manager.users.colin = let sysconfig = config; in { config, ... }: {
    # sublime music player
    xdg.configFile."sublime-music/config.json".source =
      config.lib.file.mkOutOfStoreSymlink sysconfig.sops.secrets.sublime_music_config.path;
  };
}
