{ config, lib, pkgs, ... }:

let
  install-iwd = pkgs.static-nix-shell.mkBash {
    pname = "install-iwd";
    src = ../../../../scripts;
    pkgs = [ "gnused" ];
  };
in
{
  config = lib.mkIf config.sane.roles.client {
    sane.fs."/var/lib/iwd/.secrets.psk.stamp" = {
      wantedBeforeBy = [ "iwd.service" ];
      generated.acl.mode = "0600";
      generated.script.script = ''
        ${install-iwd}/bin/install-iwd $@
        touch "/var/lib/iwd/.secrets.psk.stamp"
      '';
      generated.script.scriptArgs = [ "/run/secrets/net" "/var/lib/iwd" ];
    };
  };
}
