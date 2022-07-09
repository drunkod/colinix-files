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
  options = {
    colinsane.impermanence.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    environment.persistence."/nix/persist" = {
      directories = [
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/archive"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/dev"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/records"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/ref"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/tmp"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/use"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/Music"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/Pictures"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/Videos"; }

        # actual monero blockchain (not wallet/etc; safe to delete, just slow to regenerate)
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.bitmonero"; }
        # cache is probably too big to fit on the tmpfs
        # TODO: we could bind-mount it to something which gets cleared per boot, though.
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.cache"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.cargo"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.rustup"; }
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.ssh"; }
        # intentionally omitted:
        # "/home/colin/.config"  # managed by home-manager
        # "/home/colin/.local"   # nothing useful in here
        # "/home/colin/.mozilla" # managed by home-manager
        # creds. TODO: can i manage this with home-manager?
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.config/spotify"; }
        # creds, but also 200 MB of node modules, etc
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.config/discord"; }
        # creds/session keys, etc
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.config/Element"; }
        # creds, media
        { user = "colin"; group = "users"; mode = "0755"; directory = "/home/colin/.config/Signal"; }

        { user = "root"; group = "root"; mode = "0700"; directory = "/etc/NetworkManager/system-connections"; }
        # "/etc/nixos"
        { user = "root"; group = "root"; mode = "0755"; directory = "/etc/ssh"; }
        # "/var/lib/AccountsService"   # not sure what this is, but it's empty
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/alsa"; }                # preserve output levels, default devices
        # "/var/lib/blueman"           # files aren't human readable
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/bluetooth"; }           # preserve bluetooth handshakes
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/colord"; }              # preserve color calibrations (?)
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/duplicity"; }           # we need this mostly because of the size of duplicity's cache
        # "/var/lib/dhclient"          # empty on lappy; dunno about desko
        # "/var/lib/fwupd"             # not sure why this would need persistent state
        # "/var/lib/geoclue"           # empty on lappy
        # "/var/lib/lockdown"          # empty on desko; might store secrets after iOS handshake?
        # "/var/lib/logrotate.status"  # seems redundant with what's in /var/log?
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/machines"; }            # maybe not needed, but would be painful to add a VM and forget.
        # "/var/lib/misc"              # empty on lappy
        # "/var/lib/NetworkManager"    # looks to be mostly impermanent state?
        # "/var/lib/NetworkManager-fortisslvpn" # empty on lappy
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/nixos"; }               # has some uid/gid maps; not sure what happens if we lose this.
        # "/var/lib/PackageKit"        # wtf is this?
        # "/var/lib/power-profiles-daemon"  # redundant with nixos declarations
        # "/var/lib/private"           # empty on lappy
        # "/var/lib/systemd"           # nothing obviously necessary
        # "/var/lib/udisks2"           # empty on lappy
        # "/var/lib/upower"            # historic charge data. unnecessary, but maybe used somewhere?
        #
        # servo additions:
        { user = "998"; group = "996"; mode = "0755"; directory = "/var/lib/acme"; }  # TODO: mode?
        # "/var/lib/dhparams"          # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/dhparams.nix
        # "/var/lib/dovecot"
        # "/var/lib/duplicity"
        { user = "994"; group = "993"; mode = "0755"; directory = "/var/lib/gitea"; } # TODO: mode? could be more granular
        { user = "261"; group = "261"; mode = "0755"; directory = "/var/lib/ipfs"; }  # TODO: mode? could be more granular
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/jackett"; } # TODO: mode? we only need this to save Indexer creds ==> migrate to config?
        { user = "996"; group = "994"; mode = "0755"; directory = "/var/lib/jellyfin"; } # TODO: mode? could be more granular
        { user = "993"; group = "992"; mode = "0755"; directory = "/var/lib/matrix-appservice-irc"; } # TODO: mode?
        { user = "224"; group = "224"; mode = "0755"; directory = "/var/lib/matrix-synapse"; } # TODO: mode?
        { user = "221"; group = "221"; mode = "0755"; directory = "/var/lib/opendkim"; } # TODO: mode? move this to the nix config (SOPS)
        { user = "997"; group = "995"; mode = "0755"; directory = "/var/lib/pleroma"; } # TODO: mode? could be more granular
        { user = "71"; group = "71"; mode = "0755"; directory = "/var/lib/postgresql"; } # TODO: mode?
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/lib/postfix"; } # TODO: mode? could be more granular
        { user = "70"; group = "70"; mode = "0755"; directory = "/var/lib/transmission"; } # TODO: mode? we need this specifically for the stats tracking in .config/
        { user = "colin"; group = "users"; mode = "0755"; directory = "/var/lib/uninsane"; }
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/log"; }
        { user = "root"; group = "root"; mode = "0755"; directory = "/var/backup"; }  # for e.g. postgres dumps
        # TODO: what even GOES in /srv?
        { user = "root"; group = "root"; mode = "0755"; directory = "/srv"; }
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

    systemd.services.sane-sops = {
      description = "sops relies on /etc/ssh being available, so re-run its activation AFTER fs-local";
      script = config.system.activationScripts.setupSecrets.text;
      after = [ "fs-local.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}

