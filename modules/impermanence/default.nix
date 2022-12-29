# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.sane.impermanence;
  # taken from sops-nix code: checks if any secrets are needed to create /etc/shadow
  secrets-for-users = (lib.filterAttrs (_: v: v.neededForUsers) config.sops.secrets) != {};
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
  cleanName = path: let
    dashes = builtins.replaceStrings ["/"] ["-"] path;
    startswith = builtins.substring 0 1 dashes;
  in if startswith == "-"
    then substring 1 255 dashes
    else dashes
  ;

  # split the string path into a list of string components.
  # root directory "/" becomes the empty list [].
  # implicitly performs normalization so that:
  # splitPath "a//b/" => ["a" "b"]
  # splitPath "/a/b" =>  ["a" "b"]
  splitPath = str: builtins.filter (seg: (builtins.isString seg) && seg != "" ) (builtins.split "/" str);
  # return a string path, with leading slash but no trailing slash
  joinPathAbs = comps: "/" + (builtins.concatStringsSep "/" comps);
  concatPaths = paths: joinPathAbs (builtins.concatLists (builtins.map (p: splitPath p) paths));
  # normalize the given path
  normPath = str: joinPathAbs (splitPath str);
  # return the parent directory. doesn't care about leading/trailing slashes.
  parentDir = str: normPath (builtins.dirOf (normPath str));

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
    # directory = throw (builtins.toString opt.directory);
    # directory = builtins.traceVerbose opt.directory (concatPaths [ defaults.relativeTo opt.directory ]);

    ## helpful context
    store = builtins.addErrorContext ''while ingestDirOption on ${opt.directory} with attrs ${builtins.concatStringsSep " " (attrNames opt)}''
      (getStore opt);
  };

  ingestDirOptions = defaults: opts: builtins.map (ingestDirOption defaults) opts;
  ingested-home-dirs = ingestDirOptions home-dir-defaults cfg.home-dirs;
  ingested-sys-dirs = ingestDirOptions sys-dir-defaults cfg.dirs;
  ingested-dirs = ingested-home-dirs ++ ingested-sys-dirs;

  # include these anchor points as "virtual" nodes in below fs tree.
  home-dir = {
    inherit (home-dir-defaults) user group mode;
    directory = normPath home-dir-defaults.relativeTo;
  };
  root-dir = {
    inherit (sys-dir-defaults) user group mode;
    directory = normPath sys-dir-defaults.relativeTo;
  };

  unexpanded-tree = builtins.listToAttrs (builtins.map
    (dir: {
      name = dir.directory;
      value = dir;
    })
    (ingested-dirs ++ [ home-dir root-dir ])
  );

  # ensures the provided node and all parent nodes exist
  ensureNode = tree: path: (
    let
      parent-path = parentDir path;
      tree-with-parent = if parent-path == "/"
        then tree
        else ensureNode tree parent-path;
      parent = tree-with-parent."${parent-path}";
      # how to initialize this node if it doesn't exist explicitly.
      default-node = parent // { directory = path; };
    in
      { "${path}" = default-node; } // tree-with-parent
  );

  # finally, this tree has no orphan nodes
  expanded-tree = foldl' ensureNode unexpanded-tree (builtins.attrNames unexpanded-tree);
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

  config = mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.root-on-tmpfs {
      fileSystems."/" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "mode=755"
          "size=1G"
          "defaults"
        ];
      };
    })

    {
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
          backing-mount = cleanName opt.store.device;
          mount-service = cleanName opt.directory;
          perms-service = "impermanence-perms-${mount-service}";
          parent-mount-service = cleanName (parentDir opt.directory);
          parent-perms-service = "impermanence-perms-${parent-mount-service}";
          is-mount = opt ? store;
        in {
          fileSystems."${opt.directory}" = lib.mkIf is-mount {
            device = concatPaths [ opt.store.device opt.directory ];
            options = [
              "bind"
              "x-systemd.requires=${backing-mount}.mount"  # this should be implicit
              "x-systemd.after=${perms-service}.service"
              # `wants` doesn't seem to make it to the service file here :-(
              "x-systemd.wants=${perms-service}.service"
            ];
            # fsType = "bind";
            noCheck = true;
          };

          # create services which ensure the source directories exist and have correct ownership/perms before mounting
          systemd.services."${perms-service}" = let
            perms-script = pkgs.writeShellScript "impermanence-prepare-perms" ''
              path="$1"
              user="$2"
              group="$3"
              mode="$4"
              mkdir "$path" || test -d "$path"
              chmod "$mode" "$path"
              chown "$user:$group" "$path"
            '';
          in {
            description = "prepare permissions for ${opt.directory}";
            serviceConfig = {
              ExecStart = ''${perms-script} ${opt.directory} ${opt.user} ${opt.group} ${opt.mode}'';
              Type = "oneshot";
            };
            wantedBy = lib.mkIf is-mount [ "${mount-service}.mount" ];
            after = lib.mkIf (opt.directory != "/") [ "${parent-perms-service}.service" ];
            wants = lib.mkIf (opt.directory != "/") [ "${parent-perms-service}.service" ];
          };
        };
        cfgs = builtins.map cfgFor (builtins.attrValues expanded-tree);
        # cfgs = builtins.map cfgFor ingested-dirs;
        # cfgs = [ (cfgFor (ingestDirOption home-dir-defaults ".cache")) ];
        # myMerge = items: builtins.foldl' (acc: new: acc // new) {} items;
      in {
        # fileSystems = myMerge (catAttrs "fileSystems" cfgs);
        fileSystems = lib.mkMerge (builtins.catAttrs "fileSystems" cfgs);
        systemd = lib.mkMerge (catAttrs "systemd" cfgs);
      }
    )

    ({
      # secret decoding depends on /etc/ssh keys, which may be persisted
      system.activationScripts.setupSecrets.deps = [ "persist-ssh-host-keys" ];
      system.activationScripts.setupSecretsForUsers = lib.mkIf secrets-for-users {
        deps = [ "persist-ssh-host-keys" ];
      };
      # populated by ssh.nix, which persists /etc/ssh/host_keys
      system.activationScripts.persist-ssh-host-keys.text = lib.mkDefault "";
    })
  ]);
}

