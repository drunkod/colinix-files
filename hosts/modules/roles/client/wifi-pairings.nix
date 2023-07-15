{ config, lib, pkgs, ... }:

let
  install-nm = pkgs.static-nix-shell.mkPython3Bin {
    pname = "install-nm";
    src = ./.;
  };
in
{
  config = lib.mkIf config.sane.roles.client {
    sane.fs."/var/lib/iwd/.install-nm.stamp" = {
      wantedBeforeBy = [ "iwd.service" ];
      generated.acl.mode = "0600";
      generated.command = [
        "${install-nm}/bin/install-nm"
        "/run/secrets/net/all.json"
        "/var/lib/iwd"
        "--stamp" ".install-nm.stamp"
      ];
    };
  };
}
