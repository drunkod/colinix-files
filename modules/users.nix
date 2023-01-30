{ config, lib, sane-lib, ... }:

let
  inherit (builtins) attrValues;
  inherit (lib) count mapAttrs' mapAttrsToList mkIf mkMerge mkOption types;
  sane-user-cfg = config.sane.user;
  cfg = config.sane.users;
  path-lib = sane-lib.path;
  userOptions = {
    options = {
      fs = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          entries to pass onto `sane.fs` after prepending the user's home-dir to the path.
          e.g. `sane.users.colin.fs."/.config/aerc" = X`
            => `sane.fs."/home/colin/.config/aerc" = X;
        '';
      };
    };
  };
  userModule = types.submodule ({ config, ... }: {
    options = {
      inherit (userOptions) fs;
      default = mkOption {
        type = types.bool;
        default = false;
        description = ''
          only one default user may exist.
          this option determines what the `sane.user` shorthand evaluates to.
        '';
      };
    };

    # if we're the default user, inherit whatever settings were routed to the default user
    config = mkIf config.default sane-user-cfg;
  });
  processUser = user: defn: {
    sane.fs = mapAttrs' (path: value: {
      # TODO: query the user's home dir!
      name = path-lib.concat [ "/home/${user}" path ];
      inherit value;
    }) defn.fs;
  };
in
{
  options = {
    sane.users = mkOption {
      type = types.attrsOf userModule;
      default = {};
      description = ''
        options to apply to the given user.
        the user is expected to be created externally.
        configs applied at this level are simply transformed and then merged
        into the toplevel `sane` options. it's merely a shorthand.
      '';
    };

    sane.user = mkOption {
      type = types.nullOr (types.submodule userOptions);
      default = null;
      description = ''
        options to pass down to the default user
      '';
    };
  };
  config =
    let
      configs = mapAttrsToList processUser cfg;
      num-default-users = count (u: u.default) (attrValues cfg);
      take = f: {
        sane.fs = f.sane.fs;
      };
    in mkMerge [
      (take (sane-lib.mkTypedMerge take configs))
      {
        assertions = [
          {
            assertion = sane-user-cfg == null || num-default-users != 0;
            message = "cannot set `sane.user` without first setting `sane.users.<user>.default = true` for some user";
          }
          {
            assertion = num-default-users <= 1;
            message = "cannot set more than one default user";
          }
        ];
      }
    ];
}
