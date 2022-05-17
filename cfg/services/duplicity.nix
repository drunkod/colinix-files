# docs: https://search.nixos.org/options?channel=21.11&query=duplicity
{ config, pkgs, lib, ... }:

{
  services.duplicity.enable = true;
  # format: b2://$key_id:$app_key@$bucket
  # create key with: b2 create-key --bucket uninsane-host-duplicity uninsane-host-duplicity-safe listBuckets,listFiles,readBuckets,readFiles,writeFiles
  #   ^ run this until you get a key with no forward slashes :upside_down:
  #   web-created keys are allowed to delete files, which you probably don't want for an incremental backup program
  services.duplicity.targetUrl = builtins.replaceStrings ["\n"] [""] (builtins.readFile /etc/nixos/secrets/duplicity_url);
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

  # set this for the FIRST backup, then remove it to enable incremental backups
  #   (that the first backup *isn't* full i think is a defect)
  # services.duplicity.fullIfOlderThan = "always";
}
