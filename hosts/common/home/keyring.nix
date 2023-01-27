{ config, lib, sane-lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  sane.persist.home.private = [ ".local/share/keyrings" ];

  sane.fs."/home/colin/private/.local/share/keyrings/default" = {
    generated.script.script = builtins.readFile ../../../scripts/init-keyring;
    wantedBy = [ config.sane.fs."/home/colin/private".unit ];
  };
}
