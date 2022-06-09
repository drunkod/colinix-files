{ pkgs, ... }:

{
  fileSystems."/mnt/media-uninsane" = {
    # device = "sshfs#colin@uninsane.org:/opt/uninsane/media";
    device = "colin@uninsane.org:/opt/uninsane/media";
    fsType = "fuse.sshfs";
    options = [
      "x-systemd.automount"
      "_netdev"
      "user"
      "idmap=user"
      "transform_symlinks"
      "identityfile=/home/colin/.ssh/id_ed25519"
      "allow_other"
      "default_permissions"
      "uid=1000"
      "gid=1000"
    ];
  };
  environment.systemPackages = [
    pkgs.sshfs-fuse
  ];
}

