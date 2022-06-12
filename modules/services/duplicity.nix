# docs: https://search.nixos.org/options?channel=21.11&query=duplicity
{ config, lib, ... }:

with lib;
let
  cfg = config.colinsane.services.duplicity;
in
{
  options = {
    colinsane.services.duplicity.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.duplicity.enable = true;
    services.duplicity.targetUrl = ''"$DUPLICITY_URL"'';
    services.duplicity.escapeUrl = false;
    # format: PASSPHRASE=<cleartext> \n DUPLICITY_URL=b2://...
    # two sisters
    # PASSPHRASE: remote backups will be encrypted using this passphrase (using gpg)
    # DUPLICITY_URL: b2://$key_id:$app_key@$bucket
    # create key with: backblaze-b2 create-key --bucket uninsane-host-duplicity uninsane-host-duplicity-safe listBuckets,listFiles,readBuckets,readFiles,writeFiles
    #   ^ run this until you get a key with no forward slashes :upside_down:
    #   web-created keys are allowed to delete files, which you probably don't want for an incremental backup program
    #   you need to create a new application key from the web in order to first get a key which can create new keys (use env vars in the above command)
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
      "/home/colin/tmp"
      "/home/colin/Videos"
      # TODO: transitional
      "/home/colin/internal"
    ];

    services.duplicity.extraFlags = [
      # without --allow-source-mismatch, duplicity will abort if you change the hostname between backups
      "--allow-source-mismatch"
    ];

    # set this for the FIRST backup, then remove it to enable incremental backups
    #   (that the first backup *isn't* full i think is a defect)
    # services.duplicity.fullIfOlderThan = "always";

    systemd.services.duplicity.serviceConfig = {
      # rate-limit the read bandwidth in an effort to thereby prevent net upload saturation
      # this could perhaps be done better by adding a duplicity config option to replace the binary with `trickle`
      IOReadBandwidthMax = [
        "/dev/sda1 5M"
        "/dev/nvme0n1 5M"
        "/dev/mmc0 5M"
      ];
    };
  };
}
