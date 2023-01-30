{ config, lib, sane-lib, ... }:

let
  inherit (lib) mapAttrs' mapAttrsToList mkMerge mkOption types;
  cfg = config.sane.users;
  path-lib = sane-lib.path;
  userModule = types.submodule {
    options = {
      fs = mkOption {
        type = types.attrs;
        description = ''
          entries to pass onto `sane.fs` after prepending the user's home-dir to the path.
          e.g. `sane.users.colin.fs."/.config/aerc" = X`
            => `sane.fs."/home/colin/.config/aerc" = X;
        '';
      };
    };
  };
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
  };
  config =
    let
      configs = mapAttrsToList processUser cfg;
      take = f: {
        sane.fs = f.sane.fs;
      };
    in
      take (sane-lib.mkTypedMerge take configs);
}
