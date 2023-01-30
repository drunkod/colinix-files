{ config, sane-lib, ... }:

{
  # TODO: this should only be shipped on gui platforms
  sops.secrets."sublime_music_config" = {
    owner = config.users.users.colin.name;
    sopsFile = ../../../secrets/universal/sublime_music_config.json.bin;
    format = "binary";
  };
  sane.user.fs.".config/sublime-music/config.json" = sane-lib.fs.wantedSymlinkTo config.sops.secrets.sublime_music_config.path;
}
