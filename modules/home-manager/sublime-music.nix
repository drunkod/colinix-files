{ config, lib, sane-lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  # TODO: this should only be shipped on gui platforms
  sops.secrets."sublime_music_config" = {
    owner = config.users.users.colin.name;
    sopsFile = ../../secrets/universal/sublime_music_config.json.bin;
    format = "binary";
  };
  sane.fs."/home/colin/.config/sublime-music/config.json" = sane-lib.fs.wantedSymlinkTo config.sops.secrets.sublime_music_config.path;
}
