{ config, lib, pkgs, sane-lib, utils, ... }:

let
  persist-base = config.sane.persist.stores."plaintext".origin;
  device = config.sane.persist.stores."cryptClearOnBoot".origin;
  key = "${device}.key";
  underlying = sane-lib.path.concat [ persist-base "crypt/clearedonboot" ];
in
lib.mkIf config.sane.persist.enable
{
  sane.persist.stores."cryptClearOnBoot" = {
    storeDescription = ''
      stored to disk, but encrypted to an in-memory key and cleared on every boot
      so that it's unreadable after power-off
    '';
    origin = lib.mkDefault "/mnt/persist/crypt/clearedonboot";
  };


  fileSystems."${device}" = {
    device = underlying;
    fsType = "fuse.gocryptfs";
    options = [
      "nodev"
      "nosuid"
      "allow_other"
      "passfile=${key}"
      # "defaults"  # "unknown flag: --defaults. Try 'gocryptfs -help'"
    ];
    noCheck = true;
  };
  # let sane.fs know about our fileSystem and automatically add the appropriate dependencies
  sane.fs."${device}".mount = {
    # technically the dependency on the keyfile is extraneous because that *happens* to
    # be needed to init the store.
    depends = let
      cryptfile = config.sane.fs."${underlying}/gocryptfs.conf";
      keyfile = config.sane.fs."${key}";
    in [ keyfile.unit cryptfile.unit ];
  };

  # let sane.fs know how to initialize the gocryptfs store,
  # and that it MUST do so
  sane.fs."${underlying}/gocryptfs.conf".generated = let
    script = pkgs.writeShellScript "init-gocryptfs-store" ''
      backing="$1"
      passfile="$2"
      # clear the backing store
      # TODO: we should verify that it's not mounted anywhere...
      rm -rf "''${backing:?}"/*
      ${pkgs.gocryptfs}/bin/gocryptfs -quiet -passfile "$passfile" -init "$backing"
    '';
  in {
    script.scriptArgs = [ "${script}" underlying key ];
    # we need the key in order to initialize the store
    depends = [ config.sane.fs."${key}".unit ];
  };

  # let sane.fs know how to generate the key for gocryptfs
  sane.fs."${key}".generated = let
    script = pkgs.writeShellScript "gen-random-gocryptfs-key" ''
      dd if=/dev/random bs=128 count=1 | base64 --wrap=0 > "$1"
    '';
  in {
    script.scriptArgs = [ "${script}" key ];
    # no need for anyone else to be able to read the key
    acl.mode = "0400";
  };

  # TODO: could add this *specifically* to the .mount file for the encrypted fs?
  system.fsPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
}
