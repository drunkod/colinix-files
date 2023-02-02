{ config, lib, pkgs, sane-lib, ... }:
let
  inherit (builtins) elem map;
  inherit (lib) mapAttrs mapAttrsToList mkDefault mkIf mkMerge mkOption optionalAttrs types;
  cfg = config.sane.programs;
  pkgSpec = types.submodule ({ name, ... }: {
    options = {
      package = mkOption {
        type = types.package;
      };
      enableFor.system = mkOption {
        type = types.bool;
        default = false;
        description = ''
          place this program on the system PATH
        '';
      };
      enableFor.user = mkOption {
        type = types.attrsOf types.bool;
        default = {};
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

    config = {
      # package can be inferred by the attr name, allowing shorthand like
      # sane.packages.nano.enable = true;
      pkg = mkIf (pkgs ? name) (mkDefault pkgs."${name}");

      # enable this package if it's in the `suggestedPrograms` of any other enabled program
      enableFor = mkMerge (mapAttrsToList (_otherName: otherPkg:
        optionalAttrs
          (otherPkg.enableSuggested && elem name otherPkg.suggestedPrograms)
          (mkDefault otherPkg.enableFor)
      ) cfg);
    };
  });
  toPkgSpec = types.coercedTo types.package (p: { pkg = p; }) pkgSpec;

  configs = mapAttrsToList (_name: p: {
    # conditionally add to system PATH
    environment.systemPackages = mkIf p.enableFor.system [ p.package ];
    # conditionally add to user(s) PATH
    users.users = mapAttrs (user: en: optionalAttrs en {
      "${user}".packages = [ p ];
    }) p.enableFor.users;
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
      };
    in take (sane-lib.mkTypedMerge take configs);
}
