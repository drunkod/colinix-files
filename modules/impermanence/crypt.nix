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
in lib.mkIf config.sane.impermanence.enable
{
  # declare our backing storage
  sane.fs."${store.underlying.path}".dir = {};

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
    # HACK: this fs entry is provided by our mount service.
    unit = store.mount-unit;
  };

  # TODO: could add this *specifically* to the .mount file for the encrypted fs?
  environment.systemPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
}
