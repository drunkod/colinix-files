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
      "size=16G"
      "mode=777"
      "defaults"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/aa272cff-0fcc-498e-a4cb-0d95fb60631b";
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/31D3-40CB";
    fsType = "vfat";
  };


  # fileSystems."/var/lib/pleroma" = {
  #   device = "/opt/pleroma";
  #   options = [ "bind" ];
  # };

  # TODO: does transmission handle symlinks?
  fileSystems."/var/lib/transmission/Downloads" = {
    device = "/var/lib/uninsane/media";
    options = [ "bind" ];
  };
  fileSystems."/var/lib/transmission/.incomplete" = {
    device = "/var/lib/uninsane/media/incomplete";
    options = [ "bind" ];
  };

  # in-memory compressed RAM (seems to be dynamically sized)
  zramSwap = {
    enable = true;
  };

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
  swapDevices = [
    {
      label = "swap";
      # TODO: randomEncryption.enable = true;
    }
  ];
}

