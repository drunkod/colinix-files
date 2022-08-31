{ pkgs, ... }:

let sshOpts = rec {
  fsType = "fuse.sshfs";
  optionsBase = [
    "x-systemd.automount"
    "_netdev"
    "user"
    "transform_symlinks"
    "identityfile=/home/colin/.ssh/id_ed25519"
    "allow_other"
    "default_permissions"
  ];
  optionsColin = optionsBase ++ [
    "idmap=user"
    "uid=1000"
    "gid=100"
  ];
  optionsRoot = optionsBase ++ [
    "sftp_server=/run/wrappers/bin/sudo\\040/nix/store/96idbd49a410sm35kfz7j8rzp5g983qb-openssh-9.0p1/libexec/sftp-server"
  ];
};
in
{
  fileSystems."/mnt/servo-media-wan" = {
    device = "colin@uninsane.org:/var/lib/uninsane/media";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsColin;
  };
  fileSystems."/mnt/servo-media-lan" = {
    device = "colin@servo:/var/lib/uninsane/media";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsColin;
  };
  fileSystems."/mnt/servo-root-wan" = {
    device = "colin@uninsane.org:/";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsRoot;
  };
  fileSystems."/mnt/servo-root-lan" = {
    device = "colin@servo:/";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsRoot;
  };
  fileSystems."/mnt/desko-home" = {
    device = "colin@desko:/home/colin";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsColin;
  };
  fileSystems."/mnt/desko-root" = {
    device = "colin@desko:/";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsRoot;
  };

  environment.systemPackages = [
    pkgs.sshfs-fuse
  ];
}

