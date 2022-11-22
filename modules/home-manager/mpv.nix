{ config, lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  home-manager.users.colin.programs.mpv = {
    enable = true;
    config = {
      save-position-on-quit = true;
      keep-open = "yes";
    };
  };
}

