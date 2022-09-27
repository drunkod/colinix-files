# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ lib, config, impermanence, ... }:

with lib;
let
  cfg = config.sane.impermanence;
in
{
  options = {
    sane.impermanence.enable = mkOption {
      default = false;
      type = types.bool;
    };
    sane.impermanence.home-files = mkOption {
      default = [];
      type = types.listOf types.str;
    };
    sane.impermanence.home-dirs = mkOption {
      default = [];
      type = types.listOf (types.either types.str (types.attrsOf types.str));
    };
    sane.impermanence.service-dirs = mkOption {
      default = [];
      type = types.listOf (types.either types.str (types.attrsOf types.str));
    };
  };

  config = let
    map-dir = defaults: dir: if isString dir then
        map-dir defaults { directory = "${defaults.directory}${dir}"; }
      else
        defaults // dir
      ;
    map-dirs = defaults: dirs: builtins.map (map-dir defaults) dirs;

    map-home-dirs = map-dirs { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/"; };
    map-sys-dirs = map-dirs { user = "root"; group = "root"; mode = "0755"; directory = ""; };
    map-service-dirs = map-dirs { user = "root"; group = "root"; mode = "0755"; directory = ""; };

    map-home-files = files: builtins.map (f: {
      parentDirectory = {
        user = "colin";
        group = "users";
        mode = "0755";
      };
      file = "/home/colin/${f}";
    }) files;
  in mkIf cfg.enable {
    sane.image.extraDirectories = [ "/nix/persist/var/log" ];
    environment.persistence."/nix/persist" = {
      directories = (map-home-dirs ([
        # cache is probably too big to fit on the tmpfs
        # TODO: we could bind-mount it to something which gets cleared per boot, though.
        ".cache"
        ".cargo"
        ".rustup"
        ".ssh"
        # intentionally omitted:
        # ".config"  # managed by home-manager
        # ".local"   # nothing useful in here
      ] ++ cfg.home-dirs)) ++ (map-sys-dirs [
        # TODO: this `0700` here clobbers the perms for /persist/etc, breaking boot on freshly-deployed devices
        # { mode = "0700"; directory = "/etc/NetworkManager/system-connections"; }
        # "/etc/nixos"
        # "/etc/ssh"  # persist only the specific files we want, instead
        "/var/log"
        "/var/backup"  # for e.g. postgres dumps
      ]) ++ (map-service-dirs ([
        # "/var/lib/AccountsService"   # not sure what this is, but it's empty
        "/var/lib/alsa"                # preserve output levels, default devices
        # "/var/lib/blueman"           # files aren't human readable
        "/var/lib/bluetooth"           # preserve bluetooth handshakes
        "/var/lib/colord"              # preserve color calibrations (?)
        # "/var/lib/dhclient"          # empty on lappy; dunno about desko
        # "/var/lib/fwupd"             # not sure why this would need persistent state
        # "/var/lib/geoclue"           # empty on lappy
        # "/var/lib/lockdown"          # empty on desko; might store secrets after iOS handshake?
        # "/var/lib/logrotate.status"  # seems redundant with what's in /var/log?
        "/var/lib/machines"            # maybe not needed, but would be painful to add a VM and forget.
        # "/var/lib/misc"              # empty on lappy
        # "/var/lib/NetworkManager"    # looks to be mostly impermanent state?
        # "/var/lib/NetworkManager-fortisslvpn" # empty on lappy
        # "/var/lib/nixos"             # has some uid/gid maps, but we enforce these to be deterministic.
        # "/var/lib/PackageKit"        # wtf is this?
        # "/var/lib/power-profiles-daemon"  # redundant with nixos declarations
        # "/var/lib/private"           # empty on lappy
        # "/var/lib/systemd"           # nothing obviously necessary
        # "/var/lib/udisks2"           # empty on lappy
        # "/var/lib/upower"            # historic charge data. unnecessary, but maybe used somewhere?
        #
        # servo additions:
        # "/var/lib/dhparams"          # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/dhparams.nix
        # "/var/lib/dovecot"
        # "/var/lib/duplicity"
      ] ++ cfg.service-dirs));
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
        "/home/colin/.zsh_history"
        # # XXX these only need persistence because i have mutableUsers = true, i think
        # "/etc/group"
        # "/etc/passwd"
        # "/etc/shadow"
      ] ++ map-home-files cfg.home-files;
    };

    systemd.services.sane-sops = {
      description = "sops relies on /etc/ssh being available, so re-run its activation AFTER fs-local";
      script = config.system.activationScripts.setupSecrets.text;
      after = [ "fs-local.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}

