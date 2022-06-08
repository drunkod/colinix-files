# docs: https://search.nixos.org/options?channel=21.11&query=duplicity
{ secrets, config, ... }:

{
  services.duplicity.enable = true;
  services.duplicity.targetUrl = ''"$DUPLICITY_URL"'';
  services.duplicity.escapeUrl = false;
  # format: PASSPHRASE=<cleartext> \n DUPLICITY_URL=b2://...
  # two sisters
  # TODO: s/duplicity_passphrase/duplicity_env/
  services.duplicity.secretFile = config.sops.secrets.duplicity_passphrase.path;
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
    # other mounts
    "/mnt"
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

  sops.secrets."duplicity_passphrase" = {
    sopsFile = ../../../secrets/uninsane/duplicity.yaml;
    # owner = "duplicity";
  };
}
