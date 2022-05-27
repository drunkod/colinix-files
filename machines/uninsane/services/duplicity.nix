# docs: https://search.nixos.org/options?channel=21.11&query=duplicity
{ config, pkgs, lib, secrets, ... }:

{
  services.duplicity.enable = true;
  services.duplicity.targetUrl = secrets.duplicity.url;
  # format: PASSPHRASE=<cleartext>
  # two sisters
  services.duplicity.secretFile = /etc/nixos/secrets/duplicity_env;
  # NB: manually trigger with `systemctl start duplicity`
  services.duplicity.frequency = "daily";
  services.duplicity.exclude = [
    # impermanent/inconsequential data:
    "/dev"
    "/proc"
    "/run"
    "/sys"
    "/tmp"
    # bind mounted (dupes):
    "/var/lib/pleroma"
    "/var/lib/transmission/Downloads"
    "/var/lib/transmission/.incomplete"
    # data that's not worth the cost to backup:
    "/opt/uninsane/media"
  ];

  services.duplicity.extraFlags = [
    # without --allow-source-mismatch, duplicity will abort if you change the hostname between backups
    "--allow-source-mismatch"
  ];

  # set this for the FIRST backup, then remove it to enable incremental backups
  #   (that the first backup *isn't* full i think is a defect)
  # services.duplicity.fullIfOlderThan = "always";
}
