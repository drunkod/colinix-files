{ config, pkgs, lib, ... }:

{
  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
  #   fsType = "ext4";
  # };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2be70d38-79f4-41b6-bee2-bce5a25f8f7b";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    # this is the /dev/sda1 boot device.
    # by mounting this in boot, we can then run `nixos-rebuild` and it'll only take affect when booting from sda1
    # (old mmc1 boot will be preserved)
    device = "/dev/disk/by-uuid/B318-A67E";
    fsType = "vfat";
  };

  # fileSystems."/mnt/storage" = {
  #   device = "/dev/disk/by-uuid/2be70d38-79f4-41b6-bee2-bce5a25f8f7b";
  #   fsType = "ext4";
  # };

  # temporary; nix porting
  # fileSystems."/home/colin" = {
  #   device = "/mnt/storage/home/colin";
  #   options = [ "bind" ];
  # };
  # fileSystems."/boot" = {
  #   device = "/mnt/storage/boot";
  #   options = [ "bind" ];
  # };
  # fileSystems."/var/spool" = {
  #   device = "/mnt/storage/var/spool";
  #   options = [ "bind" ];
  # };
  # fileSystems."/var/lib" = {
  #   device = "/mnt/storage/var/lib";
  #   options = [ "bind" ];
  # };

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

