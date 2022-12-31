{ config, lib, pkgs, utils, ... }:

let
  store = {
    device = "/mnt/impermanence/crypt/clearedonboot";
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
        tmpdir=$(dirname "$passfile")
        mkdir -p "$backing" "$tmpdir"
        # if the key doesn't exist, it's probably not mounted => delete the backing dir
        rm -rf "''${backing:?}"/*
        # generate key. we can "safely" keep it around for the lifetime of this boot
        dd if=/dev/random bs=128 count=1 | base64 --wrap=0 > "$passfile"
        # initialize the crypt store
        gocryptfs -quiet -passfile "$passfile" -init "$backing"
      fi
    '';
  };
in lib.mkIf config.sane.impermanence.enable
{
  # the crypt store requires keys before being mounted
  sane.fs."${store.device}".depends = [
    "prepareEncryptedClearedOnBoot.service"
  ];

  systemd.services."prepareEncryptedClearedOnBoot" =
  let
    mount-unit = "${utils.escapeSystemdPath store.device}.mount";
  in {
    description = "prepare keys for ${store.device}";
    serviceConfig.ExecStart = ''
      ${prepareEncryptedClearedOnBoot}/bin/prepareEncryptedClearedOnBoot ${store.underlying.path} ${store.underlying.key}
    '';
    serviceConfig.Type = "oneshot";
    # remove implicit dep on sysinit.target
    unitConfig.DefaultDependencies = "no";

    # make sure the encrypted file system is mounted *after* its keys have been generated.
    wantedBy = [ mount-unit ];
    before = [ mount-unit ];
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

  # TODO: could add this *specifically* to the .mount file for the encrypted fs?
  environment.systemPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
}
