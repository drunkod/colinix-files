{ config, lib, pkgs, sane-lib, ... }:
let
  inherit (builtins) any elem map;
  inherit (lib)
    filterAttrs
    hasAttrByPath
    getAttrFromPath
    mapAttrs
    mapAttrsToList
    mkDefault
    mkIf
    mkOption
    optional
    optionalAttrs
    splitString
    types
  ;
  inherit (sane-lib) joinAttrsets;
  cfg = config.sane.programs;
  pkgSpec = types.submodule ({ name, ... }: {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        description = ''
          package, or `null` if the program is some sort of meta set (in which case it much EXPLICITLY be set null).
        '';
      };
      enableFor.system = mkOption {
        type = types.bool;
        default = any (en: en) (
          mapAttrsToList
            (otherName: otherPkg:
              otherName != name && elem name otherPkg.suggestedPrograms && otherPkg.enableSuggested && otherPkg.enableFor.system
            )
            cfg
        );
        description = ''
          place this program on the system PATH
        '';
      };
      enableFor.user = mkOption {
        type = types.attrsOf types.bool;
        default = joinAttrsets (mapAttrsToList (otherName: otherPkg:
           optionalAttrs
             (otherName != name && elem name otherPkg.suggestedPrograms && otherPkg.enableSuggested)
             (filterAttrs (user: en: en) otherPkg.enableFor.user)
        ) cfg);
        description = ''
          place this program on the PATH for some specified user(s).
        '';
      };
      suggestedPrograms = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          list of other programs a user may want to enable alongside this one.
          for example, the gnome desktop environment would suggest things like its settings app.
        '';
      };
      enableSuggested = mkOption {
        type = types.bool;
        default = true;
      };
      dir = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "list of home-relative paths to persist for this package";
      };
      private = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "list of home-relative paths to persist (in encrypted format) for this package";
      };
    };

    config =
      let
        pkgPath = splitString "." name;
      in {
        # package can be inferred by the attr name, allowing shorthand like
        #   `sane.packages.nano.enable = true;`
        package = mkIf (hasAttrByPath pkgPath pkgs) (mkDefault (getAttrFromPath pkgPath pkgs));
      };

  });
  toPkgSpec = types.coercedTo types.package (p: { package = p; }) pkgSpec;

  configs = mapAttrsToList (_name: p: {
    # conditionally add to system PATH
    environment.systemPackages = optional
      (p.package != null && p.enableFor.system)
      p.package;
    # conditionally add to user(s) PATH
    users.users = mapAttrs (user: en: optionalAttrs en {
      packages = [ p.package ];
    }) p.enableFor.user;
    # conditionally persist relevant user dirs
    sane.users = mapAttrs (user: en: optionalAttrs en {
      persist.plaintext = p.dir;
      persist.private = p.private;
    }) p.enableFor.user;
  }) cfg;
in
{
  options = {
    sane.programs = mkOption {
      type = types.attrsOf toPkgSpec;
      default = {};
    };
  };

  config =
    let
      take = f: {
        environment.systemPackages = f.environment.systemPackages;
        users.users = f.users.users;
        sane.users = f.sane.users;
      };
    in
      take (sane-lib.mkTypedMerge take configs);
}
