{ pkgs, sane-lib, ... }:

let fsOpts = rec {
  common = [
    "_netdev"
    "noatime"
    "x-systemd.requires=network-online.target"
    "x-systemd.after=network-online.target"
  ];
  sshCommon = common ++ [
    "user"
    "identityfile=/home/colin/.ssh/id_ed25519"
    "allow_other"
    "default_permissions"
  ];
  sshColin = sshCommon ++ [
    "transform_symlinks"
    "idmap=user"
    "uid=1000"
    "gid=100"
  ];
  sshRoot = sshCommon ++ [
    # we don't transform_symlinks because that breaks the validity of remote /nix stores
    "sftp_server=/run/wrappers/bin/sudo\\040/run/current-system/sw/libexec/sftp-server"
  ];
  auto = [ "x-systemd.automount" ];
  noauto = [ "noauto" ];
  wg = [
    "x-systemd.requires=wireguard-wg-home.service"
    "x-systemd.after=wireguard-wg-home.service"
  ];
  # in the event of hunt NFS mounts, consider:
  # - <https://unix.stackexchange.com/questions/31979/stop-broken-nfs-mounts-from-locking-a-directory>
};
in
{
  environment.pathsToLink = [
    # needed to achieve superuser access for user-mounted filesystems (see optionsRoot above)
    # we can only link whole directories here, even though we're only interested in pkgs.openssh
    "/libexec"
  ];

  fileSystems."/mnt/servo-nfs" = {
    device = "servo-hn:/";
    noCheck = true;
    fsType = "nfs";
    options = fsOpts.common ++ fsOpts.auto ++ fsOpts.wg;
  };
  # fileSystems."/mnt/servo-media-nfs" = {
  #   device = "servo-hn:/media";
  #   noCheck = true;
  #   fsType = "nfs";
  #   options = fsOpts.common ++ fsOpts.auto;
  # };
  sane.fs."/mnt/servo-media" = sane-lib.fs.wantedSymlinkTo "/mnt/servo-nfs/media";

  fileSystems."/mnt/servo-media-wan" = {
    device = "colin@uninsane.org:/var/lib/uninsane/media";
    fsType = "fuse.sshfs";
    options = fsOpts.sshColin ++ fsOpts.noauto;
    noCheck = true;
  };
  fileSystems."/mnt/servo-media-lan" = {
    device = "colin@servo:/var/lib/uninsane/media";
    fsType = "fuse.sshfs";
    options = fsOpts.sshColin ++ fsOpts.noauto;
    noCheck = true;
  };
  fileSystems."/mnt/servo-root-wan" = {
    device = "colin@uninsane.org:/";
    fsType = "fuse.sshfs";
    options = fsOpts.sshRoot ++ fsOpts.noauto;
    noCheck = true;
  };
  fileSystems."/mnt/servo-root-lan" = {
    device = "colin@servo:/";
    fsType = "fuse.sshfs";
    options = fsOpts.sshRoot ++ fsOpts.noauto;
    noCheck = true;
  };
  fileSystems."/mnt/desko-home" = {
    device = "colin@desko:/home/colin";
    fsType = "fuse.sshfs";
    options = fsOpts.sshColin ++ fsOpts.noauto;
    noCheck = true;
  };
  fileSystems."/mnt/desko-root" = {
    device = "colin@desko:/";
    fsType = "fuse.sshfs";
    options = fsOpts.sshRoot ++ fsOpts.noauto;
    noCheck = true;
  };

  environment.systemPackages = [
    pkgs.sshfs-fuse
  ];
}

