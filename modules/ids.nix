{ lib, config, ... }:

with lib;
let
  cfg = config.sane.ids;
  id = types.submodule {
    options = {
      uid = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      gid = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
    };
  };

  userOpts = { name, ... }: {
    config =
    let
      ent-ids = cfg."${name}" or {};
      uid = ent-ids.uid or null;
    in
    {
      uid = lib.mkIf (uid != null) uid;
    };
  };

  groupOpts = { name, ... }: {
    config =
    let
      ent-ids = cfg."${name}" or {};
      gid = ent-ids.gid or null;
    in
    {
      gid = lib.mkIf (gid != null) gid;
    };
  };
in
{
  options = {
    sane.ids = mkOption {
      type = types.attrsOf id;
      default = {};
    };
    users.users = mkOption {
      type = types.attrsOf (types.submodule userOpts);
    };
    users.groups = mkOption {
      type = types.attrsOf (types.submodule groupOpts);
    };
  };

  config = {
    # guarantee determinism in uid/gid generation for users:
    assertions = let
      uidAssertions = builtins.attrValues (builtins.mapAttrs (name: user: {
        assertion = user.uid != null;
        message = "non-deterministic uid detected for: ${name}";
      }) config.users.users);
      gidAssertions = builtins.attrValues (builtins.mapAttrs (name: group: {
        assertion = group.gid != null;
        message = "non-deterministic gid detected for: ${name}";
      }) config.users.groups);
      autoSubAssertions = builtins.attrValues (builtins.mapAttrs (name: user: {
        assertion = !user.autoSubUidGidRange;
        message = "non-deterministic subUids/Guids detected for: ${name}";
      }) config.users.users);
    in uidAssertions ++ gidAssertions ++ autoSubAssertions;
  };
}
