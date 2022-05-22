{ config, pkgs, lib, ... }:

{
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-uuid/d969ee61-12cf-4490-be07-4440c7be593f";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "defaults"
    ];
  };

  fileSystems."/boot" = {
    device = lib.mkDefault "/dev/disk/by-uuid/F826-6192";
    fsType = "vfat";
  };
}
