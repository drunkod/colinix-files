# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ config, impermanence, lib, pkgs, ... }:

with lib;
let
  cfg = config.sane.impermanence;
  # taken from sops-nix code: checks if any secrets are needed to create /etc/shadow
  secretsForUsers = (lib.filterAttrs (_: v: v.neededForUsers) config.sops.secrets) != {};
  persist-base = "/nix/persist";
  encrypted-clear-on-boot-base = "/mnt/crypt/clearedonboot";
  encrypted-clear-on-boot-store = "/nix/persist/crypt/clearedonboot";
  encrypted-clear-on-boot-key = "/mnt/crypt/clearedonboot.key";  # TODO: move this to /tmp, but that requires tmp be mounted first?
  home-dir-defaults = {
    user = "colin";
    group = "users";
    mode = "0755";
    relativeTo = "/home/colin/";
  };
  sys-dir-defaults = {
    user = "root";
    group = "root";
    mode = "0755";
    relativeTo = "";
  };

  # turn a path into a name suitable for systemd
  clean-name = path: let
    dashes = builtins.replaceStrings ["/"] ["-"] path;
    startswith = builtins.substring 0 1 dashes;
  in if startswith == "-"
    then substring 1 255 dashes
    else dashes
  ;

  dir-options = defaults: types.submodule {
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

  ingest-dir-option = defaults: opt:
    if isString opt then
      ingest-dir-option defaults { directory = opt; }
    else
      rec {
        encryptedClearOnBoot = opt.encryptedClearOnBoot or false;
        srcDevice = if encryptedClearOnBoot
          then encrypted-clear-on-boot-base
          else persist-base
        ;
        srcPath = "${srcDevice}${directory}";
        directory = defaults.relativeTo + opt.directory;
        user = opt.user or defaults.user;
        group = opt.group or defaults.group;
        mode = opt.mode or defaults.mode;
      }
    ;
  ingest-dir-options = defaults: opts: builtins.map (ingest-dir-option defaults) opts;
  ingested-home-dirs = ingest-dir-options home-dir-defaults cfg.home-dirs;
  ingested-sys-dirs = ingest-dir-options sys-dir-defaults cfg.dirs;
  ingested-default-dirs = ingest-dir-options sys-dir-defaults [
    "/var/log"
    "/var/backup"  # for e.g. postgres dumps
    # TODO: move elsewhere
    "/var/lib/alsa"                # preserve output levels, default devices
    "/var/lib/bluetooth"           # preserve bluetooth handshakes
    "/var/lib/colord"              # preserve color calibrations (?)
    "/var/lib/machines"            # maybe not needed, but would be painful to add a VM and forget.
  ];
  ingested-dirs = ingested-home-dirs ++ ingested-sys-dirs ++ ingested-default-dirs;
  ingested-crypt-dirs = builtins.filter (o: o.encryptedClearOnBoot) ingested-dirs;
  ingested-plain-dirs = builtins.filter (o: !o.encryptedClearOnBoot) ingested-dirs;
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
    sane.impermanence.encrypted-clear-on-boot = mkOption {
      default = builtins.any (opt: opt.encryptedClearOnBoot) ingested-dirs;
      type = types.bool;
      description = "define ${encrypted-clear-on-boot-base} to be an encrypted filesystem which is unreadable after power-off";
    };
    sane.impermanence.home-dirs = mkOption {
      default = [];
      type = types.listOf (types.either types.str (dir-options home-dir-defaults));
    };
    sane.impermanence.dirs = mkOption {
      default = [];
      type = types.listOf (types.either types.str (dir-options sys-dir-defaults));
    };
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

    (lib.mkIf cfg.encrypted-clear-on-boot {
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
      in {
        text = ''${script}/bin/prepareEncryptedClearedOnBoot ${encrypted-clear-on-boot-store} ${encrypted-clear-on-boot-key}'';
      };

      fileSystems."${encrypted-clear-on-boot-base}" = {
        device = encrypted-clear-on-boot-store;
        fsType = "fuse.gocryptfs";
        options = [
          "nodev"
          "nosuid"
          "allow_other"
          "passfile=${encrypted-clear-on-boot-key}"
          "defaults"
        ];
        noCheck = true;
      };

      environment.systemPackages = [ pkgs.gocryptfs ];  # fuse needs to find gocryptfs

      system.activationScripts.createPersistentStorageDirs.deps = [ "prepareEncryptedClearedOnBoot" ];
    })

    (
      let cfgFor = opt:
        let
          parent-mount = "mnt-crypt-clearedonboot";
          mount-service = clean-name opt.directory;
          perms-service = "impermanence-perms-${mount-service}";
        in {
          fileSystems = {
            name = opt.directory;
            value = {
              device = opt.srcPath;
              options = [
                "bind"
                "x-systemd.requires=${parent-mount}.mount"
                "x-systemd.after=${perms-service}.service"
                # `wants` doesn't seem to make it to the service file here :-(
                "x-systemd.wants=${perms-service}.service"
              ];
              # fsType = "bind";
              noCheck = true;
            };
          };

          # create services which ensure the source directories exist and have correct ownership/perms before mounting
          systemd.services = {
            name = "${perms-service}";
            value = {
              description = "prepare permissions for ${opt.directory}";
              serviceConfig = {
                ExecStart = pkgs.writeShellScript "${perms-service}" ''
                  mkdir -p ${opt.srcPath}
                  chmod ${opt.mode} ${opt.srcPath}
                  chown ${opt.user}:${opt.group} ${opt.srcPath}
                '';
                Type = "oneshot";
              };
              after = [ "${parent-mount}.mount" ];
              wants = [ "${parent-mount}.mount" ];
              wantedBy = [ "${mount-service}.mount" ];
            };
          };
        };
      in {
        fileSystems = builtins.listToAttrs (builtins.map (opt: (cfgFor opt).fileSystems) ingested-crypt-dirs);
        systemd.services = builtins.listToAttrs (builtins.map (opt: (cfgFor opt).systemd.services) ingested-crypt-dirs);
      }
    )

    ({
      # make sure logs from initrd can be persisted to disk -- i think?
      sane.image.extraDirectories = [ "/nix/persist/var/log" ];

      environment.persistence."${persist-base}".directories = builtins.map (opt: {
        inherit (opt) directory user group mode;
      }) ingested-plain-dirs;

      # for each edge in a mount path, impermanence gives that target directory the same permissions
      # as the matching folder in /nix/persist.
      # /nix/persist is often created with poor permissions. so patch them to get the desired directory permissions.
      system.activationScripts.fixImpermanencePerms = {
        text = "chmod ${config.users.users.colin.homeMode} /nix/persist/home/colin";
        deps = [ "users" ];
      };
      system.activationScripts.createPersistentStorageDirs.deps = [ "fixImpermanencePerms" ];

      # secret decoding depends on /etc/ssh keys, which may be persisted
      system.activationScripts.setupSecrets.deps = [ "persist-ssh-host-keys" ];
      system.activationScripts.setupSecretsForUsers = lib.mkIf secretsForUsers {
        deps = [ "persist-ssh-host-keys" ];
      };
      # populated by ssh.nix, which persists /etc/ssh/host_keys
      system.activationScripts.persist-ssh-host-keys.text = lib.mkDefault "";
    })
  ]);
}

