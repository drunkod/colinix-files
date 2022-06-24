{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/985a0a32-da52-4043-9df7-615adec2e4ff";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "defaults"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CAA7-E7D2";
    fsType = "vfat";
  };
}
