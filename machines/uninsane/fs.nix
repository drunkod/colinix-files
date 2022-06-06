{ lib, ... }:

{
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-uuid/2be70d38-79f4-41b6-bee2-bce5a25f8f7b";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = lib.mkDefault "/dev/disk/by-uuid/B318-A67E";
    fsType = "vfat";
  };


  fileSystems."/var/lib/pleroma" = {
    device = "/opt/pleroma";
    options = [ "bind" ];
  };

  fileSystems."/var/lib/transmission/Downloads" = {
    device = "/opt/uninsane/media";
    options = [ "bind" ];
  };
  fileSystems."/var/lib/transmission/.incomplete" = {
    device = "/opt/uninsane/media/incomplete";
    options = [ "bind" ];
  };

  # in-memory compressed RAM (seems to be dynamically sized)
  zramSwap = {
    enable = true;
  };

  swapDevices = [
    { device = "/swapfile"; size = 4096; }
  ];
}

