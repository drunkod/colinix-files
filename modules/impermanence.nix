# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ lib, config, impermanence, ... }:

with lib;
let
  cfg = config.colinsane.impermanence;
in
{
  imports = [
    # TODO: move to flake.nix?
    impermanence.nixosModule
  ];
  options = {
    colinsane.impermanence.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    environment.persistence."/nix/persist" = {
      directories = [
        "/home/colin/archive"
        "/home/colin/dev"
        "/home/colin/ref"
        "/home/colin/tmp"
        "/home/colin/Music"
        "/home/colin/Pictures"
        "/home/colin/Videos"

        # cache is probably too big to fit on the tmpfs
        # TODO: we could bind-mount it to something which gets cleared per boot, though.
        "/home/colin/.cache"
        "/home/colin/.ssh"
        # intentionally omitted:
        # "/home/colin/.config"  # managed by home-manager
        # "/home/colin/.local"   # nothing useful in here
        # "/home/colin/.mozilla" # managed by home-manager
        "/home/colin/.config/spotify"  # TODO: can i manage this with home-manager?

        "/etc/NetworkManager/system-connections"
        # "/etc/nixos"
        "/etc/ssh"
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
        "/var/lib/nixos"               # has some uid/gid maps; not sure what happens if we lose this.
        # "/var/lib/PackageKit"        # wtf is this?
        # "/var/lib/power-profiles-daemon"  # redundant with nixos declarations
        # "/var/lib/private"           # empty on lappy
        # "/var/lib/systemd"           # nothing obviously necessary
        # "/var/lib/udisks2"           # empty on lappy
        # "/var/lib/upower"            # historic charge data. unnecessary, but maybe used somewhere?
        "/var/log"
        # TODO: what even GOES in /srv?
        "/srv"
      ];
      files = [
        "/etc/machine-id"
        # "/home/colin/knowledge"
        "/home/colin/.zsh_history"
        # # XXX these only need persistence because i have mutableUsers = true, i think
        # "/etc/group"
        # "/etc/passwd"
        # "/etc/shadow"
        # { file = "/home/test2"; persistentStoragePath = "/nix/persist"; }
      ];
    };
  };
}

