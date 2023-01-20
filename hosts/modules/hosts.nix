{ config, lib, ... }:

let
  inherit (lib) attrValues filterAttrs mkMerge mkOption types;
  cfg = config.sane.hosts;

  host = types.submodule ({ config, ... }: {
    options = {
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
  };

  config = {
    # TODO: this should be populated per-host
    sane.hosts.by-name."desko" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU5GlsSfbaarMvDA20bxpSZGWviEzXGD8gtrIowc1pX";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFw9NoRaYrM6LbDd3aFBc4yyBlxGQn8HjeHd/dZ3CfHk";
    };
    sane.hosts.by-name."lappy" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpmFdNSVPRol5hkbbCivRhyeENzb9HVyf9KutGLP2Zu";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSJnqmVl9/SYQ0btvGb0REwwWY8wkdkGXQZfn/1geEc";
    };
    sane.hosts.by-name."moby" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrR+gePnl0nV/vy7I5BzrGeyVL+9eOuXHU1yNE3uCwU";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1N/IT3nQYUD+dBlU1sTEEVMxfOyMkrrDeyHcYgnJvw";
    };
    sane.hosts.by-name."servo" = {
      ssh.user_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS1qFzKurAdB9blkWomq8gI1g0T3sTs9LsmFOj5VtqX";
      ssh.host_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfdSmFkrVT6DhpgvFeQKm3Fh9VKZ9DbLYOPOJWYQ0E8";
    };
    sane.hosts.by-name."rescue" = {
      ssh.user_pubkey = null;
      ssh.host_pubkey = null;
    };
  };
}
