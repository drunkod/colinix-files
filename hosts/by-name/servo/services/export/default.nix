{ config, ... }:
{
  imports = [
    ./nfs.nix
    ./sftpgo.nix
  ];


  fileSystems."/var/export/media" = {
    # everything in here could be considered publicly readable (based on the viewer's legal jurisdiction)
    device = "/var/lib/uninsane/media";
    options = [ "rbind" ];
  };
  fileSystems."/var/export/playground" = {
    device = config.fileSystems."/mnt/persist/ext".device;
    fsType = "btrfs";
    options = [
      "subvol=export-playground"
      "compress=zstd"
      "defaults"
    ];
  };

  sane.fs."/var/export/README.md" = {
    wantedBy = [ "nfs.service" "sftpgo.service" ];
    file.text = ''
      - media/         read-only:  Videos, Music, Books, etc
      - playground/    read-write: use it to share files with other users of this server
    '';
  };

  # sane.fs."/var/lib/sftpgo/export/playground/README.md" = {
  #   wantedBy = [ "nfs.service" "sftpgo.service" ];
  #   file.text = ''
  #     this directory is intentionally read+write by anyone.
  #     there are no rules, except a server-level quota:
  #     - share files
  #     - write poetry
  #     - be a friendly troll
  #   '';
  # };
}
