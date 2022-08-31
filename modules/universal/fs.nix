{ pkgs, ... }:

let sshOpts = rec {
  fsType = "fuse.sshfs";
  optionsBase = [
    "x-systemd.automount"
    "_netdev"
    "user"
    "idmap=user"
    "transform_symlinks"
    "identityfile=/home/colin/.ssh/id_ed25519"
    "allow_other"
    "default_permissions"
  ];
  optionsColin = optionsBase ++ [
    "uid=1000"
    "gid=100"
  ];
  # optionsRoot = optionsBase ++ [
  #   "uid=0"
  #   "gid=0"
  # ];
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
    # options = sshOpts.optionsRoot;
    options = sshOpts.optionsColin;
  };
  fileSystems."/mnt/servo-root-lan" = {
    device = "colin@servo:/";
    inherit (sshOpts) fsType;
    # options = sshOpts.optionsRoot;
    options = sshOpts.optionsColin;
  };
  fileSystems."/mnt/desko-home" = {
    device = "colin@desko:/home/colin";
    inherit (sshOpts) fsType;
    options = sshOpts.optionsColin;
  };

  environment.systemPackages = [
    pkgs.sshfs-fuse
  ];
}

