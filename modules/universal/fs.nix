{ pkgs, ... }:

let sshOpts = {
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
  fileSystems."/mnt/servo-media-wan" = {
    device = "colin@uninsane.org:/var/lib/uninsane/media";
    inherit (sshOpts) fsType options;
  };
  fileSystems."/mnt/servo-media-lan" = {
    device = "colin@servo:/var/lib/uninsane/media";
    inherit (sshOpts) fsType options;
  };
  fileSystems."/mnt/desko-home" = {
    device = "colin@desko:/home/colin";
    inherit (sshOpts) fsType options;
  };

  environment.systemPackages = [
    pkgs.sshfs-fuse
  ];
}

