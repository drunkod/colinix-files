{ config, lib, pkgs, modulesPath, ... }:
{
  fileSystems."/" = {
    # boot by label instead of unpredictable uuid
    device = "/dev/disk/by-label/nixos-img";
    # make-disk-image only supports ext4
    fsType = "ext4";
  };
  # fileSystems."/boot".device = "/dev/vda1";
  fileSystems."/boot".device = "/dev/disk/by-label/ESP";

  system.build.raw = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    partitionTableType = "efi";
    label = "nixos-img";
    fsType = config.fileSystems."/".fsType;
    diskSize = "auto";
    format = "raw";
  };
}

