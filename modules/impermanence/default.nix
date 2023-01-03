# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ config, lib, pkgs, utils, ... }:

with lib;
let
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

  # split the string path into a list of string components.
  # root directory "/" becomes the empty list [].
  # implicitly performs normalization so that:
  # splitPath "a//b/" => ["a" "b"]
  # splitPath "/a/b" =>  ["a" "b"]
  splitPath = str: builtins.filter (seg: (builtins.isString seg) && seg != "" ) (builtins.split "/" str);
  # return a string path, with leading slash but no trailing slash
  joinPathAbs = comps: "/" + (builtins.concatStringsSep "/" comps);
  concatPaths = paths: joinPathAbs (builtins.concatLists (builtins.map (p: splitPath p) paths));
  # return the path from `from` to `to`, but generally in absolute form.
  # e.g. `pathFrom "/home/colin" "/home/colin/foo/bar"` -> "/foo/bar"
  pathFrom = from: to:
    assert lib.hasPrefix from to;
    lib.removePrefix from to;

  # options for a single mountpoint / persistence
  dirEntryOptions = {
    options = {
      directory = mkOption {
        type = types.str;
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

  dirsModule = types.submodule ({ config, ... }: {
    options = {
      home = mkOption {
        description = "directories to persist to disk, relative to a user's home ~";
        default = {};
        type = types.submodule {
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
      };
      sys = mkOption {
        description = "directories to persist to disk, relative to the fs root /";
        default = {};
        type = types.submodule {
          options = {
            plaintext = mkOption {
              default = [];
              type = types.listOf contextualizedDirOrShorthand;
              description = "list of directories (and optional config) to persist to disk in plaintext, relative to the fs root /";
            };
          };
        };
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
          directory = concatPaths [ relativeTo d.directory ];
          store = cfg.stores."${store}";
        })
        dirs
      );
    in {
      all = (mapDirs "/home/colin" "plaintext"        config.home.plaintext)
         ++ (mapDirs "/home/colin" "private"          config.home.private)
         ++ (mapDirs "/home/colin" "cryptClearOnBoot" config.home.cryptClearOnBoot)
         ++ (mapDirs "/"           "plaintext"        config.sys.plaintext);
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

  config = mkIf cfg.enable (lib.mkMerge [
    {
      # TODO: move to sane.fs, to auto-ensure all user dirs?
      sane.fs."/home/colin".dir.acl = {
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
      sane.fs."/nix/persist/home/colin".dir.acl = config.sane.fs."/home/colin".dir.acl;
      sane.fs."/mnt/impermanence/crypt/clearedonboot/home/colin".dir.acl = config.sane.fs."/home/colin".dir.acl;
    }

    (
      let cfgFor = opt:
        let
          store = opt.store;
          store-rel-path = pathFrom store.prefix opt.directory;
          backing-path = concatPaths [ store.mountpt store-rel-path ];

          # pass through the perm/mode overrides
          dir-acl = {
            user = lib.mkIf (opt.user != null) opt.user;
            group = lib.mkIf (opt.group != null) opt.group;
            mode = lib.mkIf (opt.mode != null) opt.mode;
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
            # ensure the backing path has same perms as the mount point
            dir.acl = config.sane.fs."${opt.directory}".dir.acl;
          };
        };
        cfgs = builtins.map cfgFor cfg.dirs.all;
      in {
        sane.fs = lib.mkMerge (catAttrs "fs" (catAttrs "sane" cfgs));
      }
    )

  ]);
}

