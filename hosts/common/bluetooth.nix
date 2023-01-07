{ lib, pkgs, ... }:

{
  sane.fs."/var/lib/bluetooth/.secrets.stamp" = {
    wantedBeforeBy = [ "bluetooth.service" ];
    # XXX: install-bluetooth uses sed, but that's part of the default systemd unit path, it seems
    generated.script.script = builtins.readFile ../../scripts/install-bluetooth + ''
      touch "/var/lib/bluetooth/.secrets.stamp"
    '';
    generated.script.scriptArgs = [ "/run/secrets/bt" ];
  };
}
