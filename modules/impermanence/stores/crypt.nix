{ config, lib, pkgs, utils, ... }:

let
  store = rec {
    device = "/mnt/impermanence/crypt/clearedonboot";
    mount-unit = config.sane.fs."${device}".mount.unit;
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
in
lib.mkIf config.sane.impermanence.enable
{
  sane.impermanence.stores."cryptClearOnBoot" = {
    storeDescription = ''
      stored to disk, but encrypted to an in-memory key and cleared on every boot
      so that it's unreadable after power-off
    '';
    mountpt = "/mnt/impermanence/crypt/clearedonboot";
  };

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
  # let sane.fs know about our fileSystem and automatically add the appropriate dependencies
  sane.fs."${store.device}".mount = {};

  # let the fs ensure the underlying path is also created
  sane.fs."${store.underlying.path}".dir = {};

  # TODO: could add this *specifically* to the .mount file for the encrypted fs?
  system.fsPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
}
