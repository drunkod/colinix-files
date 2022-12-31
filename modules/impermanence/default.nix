# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ config, lib, pkgs, utils, ... }:

with lib;
let
  cfg = config.sane.impermanence;
  getStore = { encryptedClearOnBoot, ... }: (
    if encryptedClearOnBoot then {
      device = "/mnt/impermanence/crypt/clearedonboot";
      underlying = {
        path = "/nix/persist/crypt/clearedonboot";
        # TODO: consider moving this to /tmp, but that requires tmp be mounted first?
        type = "gocryptfs";
        key = "/mnt/impermanence/crypt/clearedonboot.key";
      };
    } else {
      device = "/nix/persist";
      # device = "/mnt/impermenanence/persist/plain";
      # underlying = {
      #   path = "/nix/persist";
      #   type = "bind";
      # };
    }
  );

  # turn a path into a name suitable for systemd
  cleanName = utils.escapeSystemdPath;

  # split the string path into a list of string components.
  # root directory "/" becomes the empty list [].
  # implicitly performs normalization so that:
  # splitPath "a//b/" => ["a" "b"]
  # splitPath "/a/b" =>  ["a" "b"]
  splitPath = str: builtins.filter (seg: (builtins.isString seg) && seg != "" ) (builtins.split "/" str);
  # return a string path, with leading slash but no trailing slash
  joinPathAbs = comps: "/" + (builtins.concatStringsSep "/" comps);
  concatPaths = paths: joinPathAbs (builtins.concatLists (builtins.map (p: splitPath p) paths));

  # options for a single mountpoint / persistence
  dirEntry = types.submodule {
    options = {
      directory = mkOption {
        type = types.str;
      };
      encryptedClearOnBoot = mkOption {
        default = false;
        type = types.bool;
      };
      user = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      group = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      mode = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
  # allow "bar/baz" as shorthand for { directory = "bar/baz"; }
  coercedDirEntry = types.coercedTo types.str (d: { directory = d; }) dirEntry;

  # expand user options with more context
  ingestDirEntry = relativeTo: opt: {
    inherit (opt) user group mode;
    directory = concatPaths [ relativeTo opt.directory ];

    ## helpful context
    store = getStore opt;
  };

  ingestDirEntries = relativeTo: opts: builtins.map (ingestDirEntry relativeTo) opts;
  ingested-home-dirs = ingestDirEntries "/home/colin" cfg.home-dirs;
  ingested-sys-dirs = ingestDirEntries "/" cfg.dirs;
  ingested-dirs = ingested-home-dirs ++ ingested-sys-dirs;
in
{
  options = {
    sane.impermanence.enable = mkOption {
      default = false;
      type = types.bool;
    };
    sane.impermanence.root-on-tmpfs = mkOption {
      default = false;
      type = types.bool;
      description = "define / to be a tmpfs. make sure to mount some other device to /nix";
    };
    sane.impermanence.home-dirs = mkOption {
      default = [];
      type = types.listOf coercedDirEntry;
      description = "list of directories (and optional config) to persist to disk, relative to the user's home ~";
    };
    sane.impermanence.dirs = mkOption {
      default = [];
      type = types.listOf coercedDirEntry;
      description = "list of directories (and optional config) to persist to disk, relative to the fs root /";
    };
  };

  imports = [
    ./root-on-tmpfs.nix
  ];

  config = mkIf cfg.enable (lib.mkMerge [
    {
      # TODO: move to sane.fs, to auto-ensure all user dirs?
      sane.fs."/home/colin".dir = {
        user = "colin";
        group = config.users.users.colin.group;
        mode = config.users.users.colin.homeMode;
      };
      # N.B.: we have a similar problem with all mounts:
      # <crypt>/.cache/mozilla won't inherit <plain>/.cache perms.
      # this is less of a problem though, since we don't really support overlapping mounts like that in the first place.
      # what is a problem is if the user specified some other dir we don't know about here.
      # like "/var", and then "/nix/persist/var" has different perms and something mounts funny.
      # TODO: just add assertions that sane.fs."${backing}/${dest}".dir == sane.fs."${dest}" for each mount point?
      sane.fs."/nix/persist/home/colin".dir = {
        user = "colin";
        group = config.users.users.colin.group;
        mode = config.users.users.colin.homeMode;
      };
      sane.fs."/mnt/impermanence/crypt/clearedonboot/home/colin".dir = {
        user = "colin";
        group = config.users.users.colin.group;
        mode = config.users.users.colin.homeMode;
      };

      # TODO: convert this to a systemd unit file?
      system.activationScripts.prepareEncryptedClearedOnBoot =
      let
        script = pkgs.writeShellApplication {
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
        store = getStore { encryptedClearOnBoot = true; };
      in {
        text = ''${script}/bin/prepareEncryptedClearedOnBoot ${store.underlying.path} ${store.underlying.key}'';
      };

      fileSystems = let
        store = getStore { encryptedClearOnBoot = true; };
      in {
        "${store.device}" = {
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
      };

      environment.systemPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs
    }

    (
      let cfgFor = opt:
        let
          # systemd creates <path>.mount services for every fileSystems entry.
          # <path> gets escaped as part of that: this code tries to guess that escaped name here.
          # backing-mount = cleanName opt.store.device;
          mount-service = cleanName opt.directory;
          backing-path = concatPaths [ opt.store.device opt.directory ];

          dir-service = config.sane.fs."${opt.directory}".service;
          backing-service = config.sane.fs."${backing-path}".service;
          # pass through the perm/mode overrides
          dir-opts = {
            user = lib.mkIf (opt.user != null) opt.user;
            group = lib.mkIf (opt.group != null) opt.group;
            mode = lib.mkIf (opt.mode != null) opt.mode;
          };
        in {
          # create destination and backing directory, with correct perms
          sane.fs."${opt.directory}".dir = dir-opts;
          sane.fs."${backing-path}".dir = dir-opts;
          # define the mountpoint.
          fileSystems."${opt.directory}" = {
            device = backing-path;
            options = [
              "bind"
              # "x-systemd.requires=${backing-mount}.mount"  # this should be implicit
              "x-systemd.after=${backing-service}"
              "x-systemd.after=${dir-service}"
              # `wants` doesn't seem to make it to the service file here :-(
              # "x-systemd.wants=${backing-service}"
              # "x-systemd.wants=${dir-service}"
            ];
            # fsType = "bind";
            noCheck = true;
          };
          systemd.services."${backing-service}".wantedBy = [ "${mount-service}.mount" ];
          systemd.services."${dir-service}".wantedBy = [ "${mount-service}.mount" ];

        };
        cfgs = builtins.map cfgFor ingested-dirs;
      in {
        fileSystems = lib.mkMerge (catAttrs "fileSystems" cfgs);
        sane.fs = lib.mkMerge (catAttrs "fs" (catAttrs "sane" cfgs));
        systemd = lib.mkMerge (catAttrs "systemd" cfgs);
      }
    )

  ]);
}

