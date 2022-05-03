{ config, pkgs, lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

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

