{ config, lib, pkgs, sane-lib, ... }:
let
  inherit (builtins) any elem map;
  inherit (lib) filterAttrs mapAttrs mapAttrsToList mkDefault mkIf mkMerge mkOption optionalAttrs types;
  inherit (sane-lib) joinAttrsets;
  cfg = config.sane.programs;
  pkgSpec = types.submodule ({ name, ... }: {
    options = {
      package = mkOption {
        type = types.package;
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
        # default = mkMerge (mapAttrsToList (_otherName: otherPkg:
        #   optionalAttrs
        #     (otherPkg.enableSuggested && elem name otherPkg.suggestedPrograms)
        #     otherPkg.enableFor.user
        # ) cfg);
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

    config = {
      # package can be inferred by the attr name, allowing shorthand like
      # sane.packages.nano.enable = true;
      package = mkIf (pkgs ? "${name}") (mkDefault pkgs."${name}");

      # enableFor = mkIf (name == "btrfs-progs") (mkDefault cfg.cryptsetup.enableFor);

      # enable this package if it's in the `suggestedPrograms` of any other enabled program
      # enableFor = mkMerge (mapAttrsToList (_otherName: otherPkg:
      #   optionalAttrs
      #     (otherPkg.enableSuggested && elem name otherPkg.suggestedPrograms)
      #     (mkDefault otherPkg.enableFor)
      # ) cfg);
    };

  });
  toPkgSpec = types.coercedTo types.package (p: { package = p; }) pkgSpec;

  configs = mapAttrsToList (_name: p: {
    # conditionally add to system PATH
    environment.systemPackages = mkIf p.enableFor.system [ p.package ];
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
    in mkMerge [
      (take (sane-lib.mkTypedMerge take configs))
      {
        # sane.programs.cryptsetup.enableFor = mkDefault cfg.btrfs-progs.enableFor;
        # sane.programs.cryptsetup.enableFor = mkMerge (mapAttrsToList (otherName: otherPkg:
        #   optionalAttrs
        #   (otherName != "cryptsetup")
        #   (mkDefault otherPkg.enableFor)
        # ) cfg);

        # sane.programs = mapAttrs (myName: _me: optionalAttrs (myName == "btrfs-progs") {
        #   enableFor = mkMerge (mapAttrsToList (otherName: otherPkg:
        #     optionalAttrs
        #     (otherName != "cryptsetup")
        #     (mkDefault otherPkg.enableFor)
        #   ) cfg);
        # }) cfg;
      }
    ];
}
