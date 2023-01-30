{ config, sane-lib, ... }:

{
  sane.persist.home.private = [ ".local/share/keyrings" ];

  sane.fs."/home/colin/private/.local/share/keyrings/default" = {
    generated.script.script = builtins.readFile ../../../scripts/init-keyring;
    wantedBy = [ config.sane.fs."/home/colin/private".unit ];
  };
}
