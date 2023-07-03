{ config, sane-lib, ... }:

{
  sane.user.persist.private = [ ".local/share/keyrings" ];

  sane.user.fs."private/.local/share/keyrings/default" = {
    generated.script.script = builtins.readFile ./init-keyring;
    # TODO: is this `wantedBy` needed? can we inherit it?
    wantedBy = [ config.sane.fs."/home/colin/private".unit ];
    wantedBeforeBy = [ ];  # don't created this as part of `multi-user.target`
  };
}