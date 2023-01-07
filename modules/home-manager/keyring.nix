{ config, lib, sane-lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  sane.fs."/home/colin/.local/share/keyrings/default" = sane-lib.fs.wanted {
    generated.script.script = builtins.readFile ../../scripts/init-keyring;
  };
}
