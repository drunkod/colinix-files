{ config, lib, ... }:

let
  inherit (lib) attrValues filterAttrs mkMerge mkOption types;
  cfg = config.sane.hosts;

  host = types.submodule ({ config, ... }: {
    options = {
      is-target = mkOption {
        type = types.bool;
        default = false;
        description = ''
          set to true if the config is being built for deployment to this host.
        '';
      };

      roles.server = mkOption {
        type = types.bool;
        default = false;
        description = ''
          whether this machine is a server for domain-level services like wireguard, rss aggregation, etc.
        '';
      };
      roles.client = mkOption {
        type = types.bool;
        default = false;
        description = ''
          whether this machine is a client to domain-level services like wireguard, rss aggregation, etc.
        '';
      };

      ssh.user_pubkey = mkOption {
        type = types.nullOr types.str;
        description = ''
          ssh pubkey that the primary user of this machine will use when connecting to other machines.
          e.g. "ssh-ed25519 AAAA<base64>".
        '';
      };
      ssh.host_pubkey = mkOption {
        type = types.nullOr types.str;
        description = ''
          ssh pubkey which this host will present to connections initiated against it.
          e.g. "ssh-ed25519 AAAA<base64>".
        '';
      };
    };
  });
in
{
  options = {
    sane.hosts.by-name = mkOption {
      type = types.attrsOf host;
      default = {};
      description = ''
        map of hostname => attrset of information specific to that host,
        like its ssh pubkey, etc.
      '';
    };
    # TODO: questionable. the target should specifically output config rather than other bits peeking at this.
    sane.hosts.target = mkOption {
      type = host;
      description = ''
        host to which the config being built applies to.
      '';
    };
  };

  config = {
    # TODO: this should be populated per-host
    sane.hosts.by-name."desko" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU5GlsSfbaarMvDA20bxpSZGWviEzXGD8gtrIowc1pX";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFw9NoRaYrM6LbDd3aFBc4yyBlxGQn8HjeHd/dZ3CfHk";
      roles.client = true;
    };
    sane.hosts.by-name."lappy" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpmFdNSVPRol5hkbbCivRhyeENzb9HVyf9KutGLP2Zu";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSJnqmVl9/SYQ0btvGb0REwwWY8wkdkGXQZfn/1geEc";
      roles.client = true;
    };
    sane.hosts.by-name."moby" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrR+gePnl0nV/vy7I5BzrGeyVL+9eOuXHU1yNE3uCwU";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1N/IT3nQYUD+dBlU1sTEEVMxfOyMkrrDeyHcYgnJvw";
      roles.client = true;
    };
    sane.hosts.by-name."servo" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS1qFzKurAdB9blkWomq8gI1g0T3sTs9LsmFOj5VtqX";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfdSmFkrVT6DhpgvFeQKm3Fh9VKZ9DbLYOPOJWYQ0E8";
      roles.server = true;
    };
    sane.hosts.by-name."rescue" = {
      ssh.user_pubkey = null;
      ssh.host_pubkey = null;
    };

    sane.hosts."target" = mkMerge (attrValues
      (filterAttrs (host: c: c.is-target) cfg.by-name)
    );
  };
}
