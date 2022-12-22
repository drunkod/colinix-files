# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ lib, config, impermanence, ... }:

with lib;
let
  cfg = config.sane.impermanence;
  # taken from sops-nix code: checks if any secrets are needed to create /etc/shadow
  secretsForUsers = (lib.filterAttrs (_: v: v.neededForUsers) config.sops.secrets) != {};
in
{
  options = {
    sane.impermanence.enable = mkOption {
      default = false;
      type = types.bool;
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

  in mkIf cfg.enable {
    sane.image.extraDirectories = [ "/nix/persist/var/log" ];
    environment.persistence."/nix/persist" = {
      directories = (map-home-dirs cfg.home-dirs) ++ (map-sys-dirs [
        # NB: this `0700` here clobbers the perms for /persist/etc, breaking boot on freshly-deployed devices
        # { mode = "0700"; directory = "/etc/NetworkManager/system-connections"; }
        # "/etc/nixos"
        # "/etc/ssh"  # persist only the specific files we want, instead
        "/var/log"
        "/var/backup"  # for e.g. postgres dumps
        # "/var/lib/AccountsService"   # not sure what this is, but it's empty
        "/var/lib/alsa"                # preserve output levels, default devices
        # "/var/lib/blueman"           # files aren't human readable
        # TODO: if we changed the bluetooth installer to auto-discover the host MAC address, we could de-persist this
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
      ] ++ cfg.service-dirs);
      # /etc/machine-id is a globally unique identifier used for:
      # - systemd-networkd: DHCP lease renewal (instead of keying by the MAC address)
      # - systemd-journald: to filter logs by host
      # - chromium (potentially to track re-installations)
      # - gdbus; system services that might upgrade to AF_LOCAL if both services can confirm they're on the same machine
      # of these, systemd-networkd is the only legitimate case to persist the machine-id.
      # depersisting it should be "safe"; edge-cases like systemd-networkd can be directed to use some other ID if necessary.
      # nixos-impermanence shows binding the host ssh priv key to this; i could probably hash the host key into /etc/machine-id if necessary.
      # files = [ "/etc/machine-id" ];
    };

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
  };
}

