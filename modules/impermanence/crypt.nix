{ config, lib, pkgs, utils, ... }:

let
  store = rec {
    device = "/mnt/impermanence/crypt/clearedonboot";
    mount-unit = "${utils.escapeSystemdPath device}.mount";
    underlying = {
      path = "/nix/persist/crypt/clearedonboot";
      # TODO: consider moving this to /tmp, but that requires tmp be mounted first?
      key = "/mnt/impermanence/crypt/clearedonboot.key";
    };
  };
  prepareEncryptedClearedOnBoot = pkgs.writeShellApplication {
    name = "prepareEncryptedClearedOnBoot";
    runtimeInputs = with pkgs; [ gocryptfs ];
    text = ''
      backing="$1"
      passfile="$2"
      if ! test -e "$passfile"
      then
        # if the key doesn't exist, it's probably not mounted => delete the backing dir
        rm -rf "''${backing:?}"/*
        # generate key. we can "safely" keep it around for the lifetime of this boot
        umask 266
        dd if=/dev/random bs=128 count=1 | base64 --wrap=0 > "$passfile"
        umask 022
        # initialize the crypt store
        gocryptfs -quiet -passfile "$passfile" -init "$backing"
      fi
    '';
  };
  private-mount-unit = ''${utils.escapeSystemdPath "/home/colin/private"}.mount'';
in lib.mkIf config.sane.impermanence.enable
{
  systemd.services."prepareEncryptedClearedOnBoot" = rec {
    description = "prepare keys for ${store.device}";
    serviceConfig.ExecStart = ''
      ${prepareEncryptedClearedOnBoot}/bin/prepareEncryptedClearedOnBoot ${store.underlying.path} ${store.underlying.key}
    '';
    serviceConfig.Type = "oneshot";
    # remove implicit dep on sysinit.target
    unitConfig.DefaultDependencies = "no";

    # we need the key directory to be created, and the backing directory to exist
    after = [
      config.sane.fs."${store.underlying.path}".unit
      # TODO: "${parentDir store.device}"
      config.sane.fs."/mnt/impermanence/crypt".unit
    ];
    wants = after;

    # make sure the encrypted file system is mounted *after* its keys have been generated.
    before = [ store.mount-unit ];
    wantedBy = before;
  };

  fileSystems."${store.device}" = {
    device = store.underlying.path;
    fsType = "fuse.gocryptfs";
    options = [
      "nodev"
      "nosuid"
      "allow_other"
      "passfile=${store.underlying.key}"
      "defaults"
    ];
    noCheck = true;
  };

  sane.fs."${store.device}" = {
    # ensure the fs is mounted only after the mountpoint directory is created
    dir.reverseDepends = [ store.mount-unit ];
    # HACK: this fs entry is provided by our mount unit.
    unit = store.mount-unit;
  };
  sane.fs."${store.underlying.path}" = {
    # don't mount until after the backing dir is setup correctly.
    # TODO: this isn't necessary? the mount-unit already depends on prepareEncryptedClearOnBoot
    # which depends on the underlying path?
    dir.reverseDepends = [ store.mount-unit ];
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
  environment.systemPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
}
