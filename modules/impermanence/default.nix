# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ config, lib, pkgs, utils, sane-lib, ... }:

with lib;
let
  path = sane-lib.path;
  sane-types = sane-lib.types;
  cfg = config.sane.impermanence;

  storeType = types.submodule {
    options = {
      mountpt = mkOption {
        type = types.str;
      };
      prefix = mkOption {
        type = types.str;
        default = "/";
        description = ''
          optional prefix to strip from children when stored here.
          for example, prefix="/var/private" and mountpoint="/mnt/crypt/private"
          would cause /var/private/www/root to be stored at /mnt/crypt/private/www/root instead of
          /mnt/crypt/private/var/private/www/root.
        '';
      };
      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          extra fstab options to include in all mounts downstream of this store.
          e.g. ["noauto" "x-systemd.wanted-by=<blah>"] to automount but only after the store is explicitly unlocked.
        '';
      };
    };
  };

  # options for a single mountpoint / persistence
  dirEntryOptions = {
    options = {
      directory = mkOption {
        type = types.str;
      };
      inherit (sane-types.aclOverrideMod.options) user group mode;
    };
  };
  contextualizedDir = types.submodule dirEntryOptions;
  # allow "bar/baz" as shorthand for { directory = "bar/baz"; }
  contextualizedDirOrShorthand = types.coercedTo
    types.str
    (d: { directory = d; })
    contextualizedDir;

  # entry whose `directory` is always an absolute fs path
  # and has an associated `store`
  contextFreeDir = types.submodule [
    dirEntryOptions
    {
      options = {
        store = mkOption {
          type = storeType;
        };
      };
    }
  ];

  dirsSubModule = types.submodule {
    options = {
      plaintext = mkOption {
        default = [];
        type = types.listOf contextualizedDirOrShorthand;
        description = "directories to persist in cleartext";
      };
      private = mkOption {
        default = [];
        type = types.listOf contextualizedDirOrShorthand;
        description = "directories to store encrypted to the user's login password and auto-decrypt on login";
      };
      cryptClearOnBoot = mkOption {
        default = [];
        type = types.listOf contextualizedDirOrShorthand;
        description = ''
          directories to store encrypted to an auto-generated in-memory key and
          wiped on boot. the main use is for sensitive cache dirs too large to fit in memory.
        '';
      };
    };
  };

  dirsModule = types.submodule ({ config, ... }: {
    options = {
      home = mkOption {
        description = "directories to persist to disk, relative to a user's home ~";
        default = {};
        type = dirsSubModule;
      };
      sys = mkOption {
        description = "directories to persist to disk, relative to the fs root /";
        default = {};
        type = dirsSubModule;
      };
      all = mkOption {
        type = types.listOf contextFreeDir;
        description = "all directories known to the config. auto-computed: users should not set this directly.";
      };
    };
    config = let
      mapDirs = relativeTo: store: dirs: (map
        (d: {
          inherit (d) user group mode;
          directory = path.concat [ relativeTo d.directory ];
          store = cfg.stores."${store}";
        })
        dirs
      );
      mapDirSets = relativeTo: dirsSubOptions: let
        # list where each elem is a list from calling mapDirs on one store at a time
        contextFreeDirSets = lib.mapAttrsToList (mapDirs relativeTo) dirsSubOptions;
      in
        builtins.concatLists contextFreeDirSets;
    in {
      all = (mapDirSets "/home/colin" config.home) ++ (mapDirSets "/" config.sys);
    };
  });
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
      description = "define / fs root to be a tmpfs. make sure to mount some other device to /nix";
    };
    sane.impermanence.dirs = mkOption {
      type = dirsModule;
      default = {};
    };
    sane.impermanence.stores = mkOption {
      type = types.attrsOf storeType;
      default = {};
      description = ''
        map from human-friendly name to a fs sub-tree from which files are linked into the logical fs.
      '';
    };
  };

  imports = [
    ./root-on-tmpfs.nix
    ./stores
  ];

  config = let
    cfgFor = opt:
      let
        store = opt.store;
        store-rel-path = path.from store.prefix opt.directory;
        backing-path = path.concat [ store.mountpt store-rel-path ];

        # pass through the perm/mode overrides
        dir-acl = sane-lib.filterNonNull {
          inherit (opt) user group mode;
        };
      in {
        # create destination and backing directory, with correct perms
        sane.fs."${opt.directory}" = {
          # inherit perms & make sure we don't mount until after the mount point is setup correctly.
          dir.acl = dir-acl;
          mount.bind = backing-path;
          mount.extraOptions = store.extraOptions;
        };
        sane.fs."${backing-path}" = {
          # ensure the backing path has same perms as the mount point.
          # TODO: maybe we want to do this, crawling all the way up to the store base?
          # that would simplify (remove) the code in stores/default.nix
          dir.acl = config.sane.fs."${opt.directory}".dir.acl;
        };
      };
  in mkIf cfg.enable {
    sane.fs = lib.mkMerge (map (d: (cfgFor d).sane.fs) cfg.dirs.all);
  };
}

