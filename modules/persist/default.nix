# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ config, lib, pkgs, utils, sane-lib, ... }:

with lib;
let
  path = sane-lib.path;
  sane-types = sane-lib.types;
  cfg = config.sane.persist;

  storeType = types.submodule {
    options = {
      storeDescription = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          an optional description of the store, which is rendered like
            {store.name}: {store.storeDescription}
          for example, a store named "private" could have description "ecnrypted to the user's password and decrypted on login".
        '';
      };
      origin = mkOption {
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
      defaultOrdering.wantedBeforeBy = mkOption {
        type = types.listOf types.str;
        default = [ "local-fs.target" ];
        description = ''
          list of units or targets which would prefer that everything in this store
          be initialized before they run, but failing to do so should not error the items in this list.
        '';
      };
      defaultOrdering.wantedBy = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          list of units or targets which, upon activation, should activate all units in this store.
        '';
      };
    };
  };

  coercedToStore = types.coercedTo types.str (s: cfg.stores."${s}") storeType;

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
          type = coercedToStore;
        };
      };
    }
  ];

  contextFreeDirSpec = types.submodule {
    options = {
      inherit (sane-types.aclOverrideMod.options) user group mode;
      store = mkOption {
        type = coercedToStore;
      };
    };
  };


  # attrset from { "${storeName}" = [ dirEntry ] }
  # the user can specify something like:
  #   <option>.private.".cache/vim" = { mode = "0700"; };
  # to place ".cache/vim" into the private store and create with the appropriate mode
  dirsSubModule = types.attrsOf (types.listOf contextualizedDirOrShorthand);
in
{
  options = {
    sane.persist.enable = mkOption {
      default = false;
      type = types.bool;
    };
    sane.persist.root-on-tmpfs = mkOption {
      default = false;
      type = types.bool;
      description = "define / fs root to be a tmpfs. make sure to mount some other device to /nix";
    };
    sane.persist.home = mkOption {
      description = "directories to persist to disk, relative to a user's home ~";
      default = {};
      type = dirsSubModule;
    };
    sane.persist.sys = mkOption {
      description = "directories to persist to disk, relative to the fs root /";
      default = {};
      type = dirsSubModule;
    };
    sane.persist.all = mkOption {
      type = types.attrsOf contextFreeDirSpec;
      description = "all directories known to the config. auto-computed: users should not set this directly.";
    };
    sane.persist.stores = mkOption {
      type = types.attrsOf storeType;
      default = {};
      description = ''
        map from human-friendly name to a fs sub-tree from which files are linked into the logical fs.
      '';
    };
  };

  imports = [
    ./computed.nix
    ./root-on-tmpfs.nix
    ./stores
  ];

  config = let
    cfgFor = fspath: opt:
      let
        store = opt.store;
        fsPathToStoreRelPath = fspath: path.from store.prefix fspath;
        fsPathToBackingPath = fspath: path.concat [ store.origin (fsPathToStoreRelPath fspath) ];

        # pass through the perm/mode overrides
        dir-acl = sane-lib.filterNonNull {
          inherit (opt) user group mode;
        };
      in [
        {
          # create destination dir, with correct perms
          sane.fs."${fspath}" = {
            # inherit perms & make sure we don't mount until after the mount point is setup correctly.
            dir.acl = dir-acl;
            mount.bind = fsPathToBackingPath fspath;
            inherit (store.defaultOrdering) wantedBy wantedBeforeBy;
          };

          # create the backing path as a dir
          sane.fs."${fsPathToBackingPath fspath}".dir = {};
        }
        {
          # default each item along the backing path to have the same acl as the location it would be mounted.
          sane.fs = sane-lib.mapToAttrs (fsSubpath: {
            name = fsPathToBackingPath fsSubpath;
            value.generated.acl = config.sane.fs."${fsSubpath}".generated.acl;
          }) (path.walk store.prefix fspath);
        }
      ];
      configsPerPath = lib.mapAttrsToList cfgFor cfg.all;
      allConfigs = builtins.concatLists configsPerPath;
  in mkIf cfg.enable {
    sane.fs = lib.mkMerge (map (c: c.sane.fs) allConfigs);
  };
}

