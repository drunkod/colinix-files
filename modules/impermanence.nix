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
  encrypted-clear-on-boot-base = "/var/lib/impermanence/cleared-on-boot";
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
      {
        encryptedClearOnBoot = opt.encryptedClearOnBoot or false;
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
      description = "define /nix/persist/crypt/cleared-on-boot to be an encrypted filesystem which is unreadable after power-off";
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
      boot.initrd.kernelModules = [ "fuse" ];

      system.activationScripts.mountEncryptedClearedOnBoot =
      let
        pass-template = "/tmp/encrypted-clear-on-boot.XXXXXXXX";
        tmpdir = "/tmp/impermanence";
        script = pkgs.writeShellApplication {
          name = "mountEncryptedClearedOnBoot";
          runtimeInputs = with pkgs; [ fuse gocryptfs ];
          text = ''
            backing="$1"
            mountpt="$2"
            if ! test -e "$mountpt"/init
            then
              mkdir -p "$backing" "$mountpt" ${tmpdir}
              rm -rf "''${backing:?}"/*
              passfile=$(mktemp ${pass-template})
              dd if=/dev/random bs=128 count=1 | base64 --wrap=0 > "$passfile"
              gocryptfs -quiet -passfile "$passfile" -init "$backing"
              mount.fuse "gocryptfs#$backing" "$mountpt" -o nodev,nosuid,allow_other,passfile="$passfile"
              # mount -t fuse.gocryptfs -o passfile="$passfile" "$backing" "$mountpt"
              # gocryptfs -quiet -passfile "$passfile" "$backing" "$mountpt"
              rm "$passfile"
              unset passfile
              touch "$mountpt"/init
            fi
          '';
        };
      in {
        deps = [ "modprobe" ];
        text = ''${script}/bin/mountEncryptedClearedOnBoot /nix/persist/crypt/cleared-on-boot "${encrypted-clear-on-boot-base}"'';
      };

      system.activationScripts.createPersistentStorageDirs.deps = [ "mountEncryptedClearedOnBoot" ];
    })

    ({
      # XXX: why is this necessary?
      sane.image.extraDirectories = [ "/nix/persist/var/log" ];

      environment.persistence = lib.mkMerge (builtins.map (opt:
        let
          base = if opt.encryptedClearOnBoot
            then encrypted-clear-on-boot-base
            else persist-base
          ;
        in {
          "${base}".directories = [
            { inherit (opt) directory user group mode; }
          ];
        }
      ) ingested-dirs);

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

