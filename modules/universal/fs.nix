{ pkgs, ... }:

let uninsane = {
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
    "gid=100"
  ];
};
in
{
  fileSystems."/mnt/media-uninsane" = {
    # device = "sshfs#colin@uninsane.org:/opt/uninsane/media";
    device = "colin@uninsane.org:/opt/uninsane/media";
    inherit (uninsane) fsType options;
  };
  fileSystems."/mnt/media-uninsane-lan" = {
    # device = "sshfs#colin@uninsane.org:/opt/uninsane/media";
    device = "colin@192.168.0.5:/opt/uninsane/media";
    inherit (uninsane) fsType options;
  };
  environment.systemPackages = [
    pkgs.sshfs-fuse
  ];
}

