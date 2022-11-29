{ ... }:

{
  # root is a tmpfs so that we have an ephemeral system ("impermanence" handles the state)
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "mode=755"
      "size=1G"
      "defaults"
    ];
  };
  # we need a /tmp for building large nix things
  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "mode=777"
      "defaults"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/cc81cca0-3cc7-4d82-a00c-6243af3e7776";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "defaults"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6EE3-4171";
    fsType = "vfat";
  };

  # in-memory compressed RAM (seems to be dynamically sized)
  # zramSwap = {
  #   enable = true;
  # };

  # btrfs doesn't easily support swapfiles
  # swapDevices = [
  #   { device = "/nix/persist/swapfile"; size = 4096; }
  # ];

  # this can be a partition. create with:
  #   fdisk <dev>
  #     n
  #     <default partno>
  #     <start>
  #     <end>
  #     t
  #     <partno>
  #     19  # set part type to Linux swap
  #     w   # write changes
  #   mkswap -L swap <part>
  # swapDevices = [
  #   {
  #     label = "swap";
  #     # TODO: randomEncryption.enable = true;
  #   }
  # ];
}

