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
  home-dir-defaults = {
    user = "colin";
    group = "users";
    mode = "0755";
    relativeTo = "/home/colin";
  };
  sys-dir-defaults = {
    user = "root";
    group = "root";
    mode = "0755";
    relativeTo = "";
  };

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

  dirOptions = defaults: types.submodule {
    options = {
      encryptedClearOnBoot = mkOption {
        default = false;
        type = types.bool;
      };
      directory = mkOption {
        type = types.str;
      };
      user = mkOption {
        type = types.str;
        default = defaults.user;
      };
      group = mkOption {
        type = types.str;
        default = defaults.group;
      };
      mode = mkOption {
        type = types.str;
        default = defaults.mode;
      };
    };
  };
  mkDirsOption = defaults: mkOption {
    default = [];
    type = types.listOf (types.coercedTo types.str (d: { directory = d; }) (dirOptions defaults));
    # apply = map (d: if isString d then { directory = d; } else d);
  };

  # expand user options with more context
  ingestDirOption = defaults: opt: {
    inherit (opt) user group mode;
    directory = concatPaths [ defaults.relativeTo opt.directory ];

    ## helpful context
    store = builtins.addErrorContext ''while ingestDirOption on ${opt.directory} with attrs ${builtins.concatStringsSep " " (attrNames opt)}''
      (getStore opt);
  };

  ingestDirOptions = defaults: opts: builtins.map (ingestDirOption defaults) opts;
  ingested-home-dirs = ingestDirOptions home-dir-defaults cfg.home-dirs;
  ingested-sys-dirs = ingestDirOptions sys-dir-defaults cfg.dirs;
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
    sane.impermanence.home-dirs = mkDirsOption home-dir-defaults;
    sane.impermanence.dirs = mkDirsOption sys-dir-defaults;
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

      # without this, we get `fusermount: fuse device not found, try 'modprobe fuse' first`.
      # - that only happens after a activation-via-boot -- not activation-after-rebuild-switch.
      # it seems likely that systemd loads `fuse` by default. see:
      # - </etc/systemd/system/sysinit.target.wants/sys-fs-fuse-connections.mount>
      #   - triggers: /etc/systemd/system/modprobe@.service
      #     - calls `modprobe`
      # note: even `boot.kernelModules = ...` isn't enough: that option creates /etc/modules-load.d/, which is ingested only by systemd.
      # note: `boot.initrd.availableKernelModules` ALSO isn't enough: idk why.
      # TODO: might not be necessary now we're using fileSystems and systemd
      boot.initrd.kernelModules = [ "fuse" ];

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
        in {
          # create destination and backing directory, with correct perms
          sane.fs."${opt.directory}".dir = {
            inherit (opt) user group mode;
          };
          sane.fs."${backing-path}".dir = {
            inherit (opt) user group mode;
          };
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

