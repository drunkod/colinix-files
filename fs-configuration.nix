{ config, pkgs, lib, ... }:

{
  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/2be70d38-79f4-41b6-bee2-bce5a25f8f7b";
    fsType = "ext4";
  };

  fileSystems."/var/lib/pleroma" = {
    device = "/mnt/storage/opt/pleroma.nix";
    options = [ "bind" ];
  };

  # swapDevices = [ 
  #   { device = "/swapfile"; size = 4096; }
  # ];
}

