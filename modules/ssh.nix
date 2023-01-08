{ lib, ... }:

with lib;
let
  key = types.submodule ({ name, config, ...}: {
    options = {
      typedPubkey = mkOption {
        type = types.str;
        description = ''
          the pubkey with type attached.
          e.g. "ssh-ed25519 <base64>"
        '';
      };
      # type = mkOption {
      #   type = types.str;
      #   description = ''
      #     the type of the key, e.g. "id_ed25519"
      #   '';
      # };
      host = mkOption {
        type = types.str;
        description = ''
          the hostname of a key
        '';
      };
      user = mkOption {
        type = types.str;
        description = ''
          the username of a key
        '';
      };
      asUserKey = mkOption {
        type = types.str;
        description = ''
          append the "user@host" value to the pubkey to make it usable for ~/.ssh/id_<x>.pub or authorized_keys
        '';
      };
      asHostKey = mkOption {
        type = types.str;
        description = ''
          prepend the "host" value to the pubkey to make it usable for ~/.ssh/known_hosts
        '';
      };
    };
    config = rec {
      user = head (lib.splitString "@" name);
      host = last (lib.splitString "@" name);
      asUserKey = "${config.typedPubkey} ${name}";
      asHostKey = "${host} ${config.typedPubkey}";
    };
  });
  coercedToKey = types.coercedTo types.str (typedPubkey: {
    inherit typedPubkey;
  }) key;
in
{
  options = {
    sane.ssh.pubkeys = mkOption {
      type = types.attrsOf coercedToKey;
      default = [];
      description = ''
        mapping from "user@host" to pubkey.
      '';
    };
  };
}
