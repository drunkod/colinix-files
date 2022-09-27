{ pkgs, ... }:

let sshOpts = rec {
  fsType = "fuse.sshfs";
  optionsBase = [
    "x-systemd.automount"
    "_netdev"
    "user"
    "identityfile=/home/colin/.ssh/id_ed25519"
    "allow_other"
    "default_permissions"
  ];
  optionsColin = optionsBase ++ [
    "transform_symlinks"
    "idmap=user"
    "uid=1000"
    "gid=100"
  ];

  optionsRoot = optionsBase ++ [
    # we don't transform_symlinks because that breaks the validity of remote /nix stores
    "sftp_server=/run/wrappers/bin/sudo\\040${pkgs.openssh}/libexec/sftp-server"
  ];
};
in
{
  fileSystems."/mnt/servo-media-wan" = {
    device = "colin@uninsane.org:/var/lib/uninsane/media";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsColin;
    noCheck = true;
  };
  fileSystems."/mnt/servo-media-lan" = {
    device = "colin@servo:/var/lib/uninsane/media";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsColin;
    noCheck = true;
  };
  fileSystems."/mnt/servo-root-wan" = {
    device = "colin@uninsane.org:/";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsRoot;
    noCheck = true;
  };
  fileSystems."/mnt/servo-root-lan" = {
    device = "colin@servo:/";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsRoot;
    noCheck = true;
  };
  fileSystems."/mnt/desko-home" = {
    device = "colin@desko:/home/colin";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsColin;
    noCheck = true;
  };
  fileSystems."/mnt/desko-root" = {
    device = "colin@desko:/";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsRoot;
    noCheck = true;
  };

  environment.systemPackages = [
    pkgs.sshfs-fuse
  ];
}

