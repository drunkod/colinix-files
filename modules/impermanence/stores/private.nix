{ config, lib, pkgs, utils, ... }:

lib.mkIf config.sane.impermanence.enable
{
  sane.impermanence.stores."private" = {
    storeDescription = ''
      encrypted to the user's password and auto-unlocked at login
    '';
    origin = "/home/colin/private";
    # files stored under here *must* have the /home/colin prefix.
    # internally, this prefix is removed so that e.g.
    # /home/colin/foo/bar when stored in `private` is visible at
    # /home/colin/private/foo/bar
    prefix = "/home/colin";
    defaultOrdering = let
      private-unit = config.sane.fs."/home/colin/private".unit;
    in {
      # auto create only after ~/private is mounted
      wantedBy = [ private-unit ];
      # we can't create things in private before local-fs.target
      wantedBeforeBy = [ ];
    };
  };

  fileSystems."/home/colin/private" = {
    device = "/nix/persist/home/colin/private";
    fsType = "fuse.gocryptfs";
    options = [
      "noauto"  # don't try to mount, until the user logs in!
      "nofail"
      "allow_other"  # root ends up being the user that mounts this, so need to make it visible to `colin`.
      "nodev"
      "nosuid"
      "quiet"
      "defaults"
    ];
    noCheck = true;
  };

  # let sane.fs know about the mount
  sane.fs."/home/colin/private".mount = {};
  # it also needs to know that the underlying device is an ordinary folder
  sane.fs."/nix/persist/home/colin/private".dir = {};

  # TODO: could add this *specifically* to the .mount file for the encrypted fs?
  system.fsPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
}

