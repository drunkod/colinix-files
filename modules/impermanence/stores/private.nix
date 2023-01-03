{ config, lib, pkgs, utils, ... }:

let
  private-mount-unit = ''${utils.escapeSystemdPath "/home/colin/private"}.mount'';
in lib.mkIf config.sane.impermanence.enable
{
  sane.impermanence.stores."private" = {
    mountpt = "/home/colin/private";
    # files stored under here *must* have the /home/colin prefix.
    # internally, this prefix is removed so that e.g.
    # /home/colin/foo/bar when stored in `private` is visible at
    # /home/colin/private/foo/bar
    prefix = "/home/colin";
    # fstab options inherited by all members of the store
    extraOptions = let
      private-unit = config.sane.fs."/home/colin/private".unit;
    in [
      "noauto"
      # auto mount when ~/private is mounted
      "x-systemd.wanted-by=${private-unit}"
    ];
  };

  fileSystems."/home/colin/private" = {
    device = "/nix/persist/home/colin/private";
    fsType = "fuse.gocryptfs";
    options = [
      "noauto"  # don't try to mount, until the user logs in!
      "allow_other"  # root ends up being the user that mounts this, so need to make it visible to `colin`.
      "nodev"
      "nosuid"
      "quiet"
      "defaults"
    ];
    noCheck = true;
  };

  sane.fs."/home/colin/private" = {
    dir.reverseDepends = [
      # mounting relies on the mountpoint first being created.
      private-mount-unit
      # ensure the directory is created during boot, and before user logs in.
      "multi-user.target"
    ];
    # HACK: this fs entry is provided by the mount unit.
    unit = private-mount-unit;
  };
  sane.fs."/nix/persist/home/colin/private" = {
    dir.reverseDepends = [
      # the mount unit relies on the source having first been created.
      # (it also relies on the cryptfs having been seeded -- which we can't verify here).
      private-mount-unit
      # ensure the directory is created during boot, and before user logs in.
      "multi-user.target"
    ];
  };

  # TODO: could add this *specifically* to the .mount file for the encrypted fs?
  system.fsPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
}

