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
  in mkIf cfg.enable {
    environment.persistence."/nix/persist" = {
      directories = (map-home-dirs [
        "archive"
        "dev"
        "records"
        "ref"
        "tmp"
        "use"
        "Music"
        "Pictures"
        "Videos"
        # actual monero blockchain (not wallet/etc; safe to delete, just slow to regenerate)
        ".bitmonero"
        # cache is probably too big to fit on the tmpfs
        # TODO: we could bind-mount it to something which gets cleared per boot, though.
        ".cache"
        ".cargo"
        ".rustup"
        ".ssh"
        # zcash coins. safe to delete, just slow to regenerate (10-60 minutes)
        ".zcash"
        # intentionally omitted:
        # ".config"  # managed by home-manager
        # ".local"   # nothing useful in here
        # ".mozilla" # managed by home-manager
        # creds. TODO: can i manage this with home-manager?
        ".config/spotify"
        # creds, but also 200 MB of node modules, etc
        ".config/discord"
        # creds/session keys, etc
        ".config/Element"
        # creds, media
        ".config/Signal"
      ]) ++ (map-sys-dirs [
        { mode = "0700"; directory = "/etc/NetworkManager/system-connections"; }
        # "/etc/nixos"
        "/etc/ssh"
        "/var/log"
        "/var/backup"  # for e.g. postgres dumps
        # TODO: what even GOES in /srv?
        "/srv"
      ]) ++ (map-service-dirs [
        # "/var/lib/AccountsService"   # not sure what this is, but it's empty
        "/var/lib/alsa"                # preserve output levels, default devices
        # "/var/lib/blueman"           # files aren't human readable
        "/var/lib/bluetooth"           # preserve bluetooth handshakes
        "/var/lib/colord"              # preserve color calibrations (?)
        "/var/lib/duplicity"           # we need this mostly because of the size of duplicity's cache
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
        #
        # servo additions:
        { user = "998"; group = "996"; directory = "/var/lib/acme"; }  # TODO: mode?
        # "/var/lib/dhparams"          # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/dhparams.nix
        # "/var/lib/dovecot"
        # "/var/lib/duplicity"
        { user = "994"; group = "993"; directory = "/var/lib/gitea"; } # TODO: mode? could be more granular
        { user = "261"; group = "261"; directory = "/var/lib/ipfs"; }  # TODO: mode? could be more granular
        { user = "root"; group = "root"; directory = "/var/lib/jackett"; } # TODO: mode? we only need this to save Indexer creds ==> migrate to config?
        { user = "996"; group = "994"; directory = "/var/lib/jellyfin"; } # TODO: mode? could be more granular
        { user = "993"; group = "992"; directory = "/var/lib/matrix-appservice-irc"; } # TODO: mode?
        { user = "224"; group = "224"; directory = "/var/lib/matrix-synapse"; } # TODO: mode?
        { user = "221"; group = "221"; directory = "/var/lib/opendkim"; } # TODO: mode? move this to the nix config (SOPS)
        { user = "997"; group = "995"; directory = "/var/lib/pleroma"; } # TODO: mode? could be more granular
        { user = "71"; group = "71"; directory = "/var/lib/postgresql"; } # TODO: mode?
        { user = "root"; group = "root"; directory = "/var/lib/postfix"; } # TODO: mode? could be more granular
        { user = "70"; group = "70"; directory = "/var/lib/transmission"; } # TODO: mode? we need this specifically for the stats tracking in .config/
        { user = "colin"; group = "users"; directory = "/var/lib/uninsane"; }
      ]);
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

