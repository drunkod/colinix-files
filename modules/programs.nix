{ config, lib, options, pkgs, sane-lib, ... }:
let
  inherit (builtins) any attrValues elem map;
  inherit (lib)
    concatMapAttrs
    filterAttrs
    hasAttrByPath
    getAttrFromPath
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkDefault
    mkIf
    mkMerge
    mkOption
    optional
    optionalAttrs
    splitString
    types
  ;
  inherit (sane-lib) joinAttrsets;
  cfg = config.sane.programs;
  # create a map:
  # {
  #   "${pkgName}" = {
  #     system = true|false;
  #     user = {
  #       "${name}" = true|false;
  #     };
  #   };
  # }
  # for every ${pkgName} in pkgSpecs.
  # `system = true|false` is a computed expression over all the other programs, as evaluated.
  solveDefaultEnableFor = pkgSpecs: lib.foldlAttrs (
    acc: pname: pval: (
      # add "${enableName}".system |= areSuggestionsEnabled pval
      # for each `enableName` in pval.suggestedPrograms.
      # do the same for `user` field.
      lib.foldl (acc': enableName: acc' // {
        "${enableName}" = let
          super = acc'."${enableName}";
        in {
          system = super.system || (pval.enableFor.system && pval.enableSuggested);
          user = super.user // lib.filterAttrs (_u: en: en && pval.enableSuggested) pval.enableFor.user;
        };
      }) acc pval.suggestedPrograms
    )
  ) (mkDefaultEnables pkgSpecs) pkgSpecs;
  mkDefaultEnables = lib.mapAttrs (_pname: _pval: { system = false; user = {}; });
  defaultEnables = solveDefaultEnableFor cfg;
  pkgSpec = types.submodule ({ config, name, ... }: {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        description = ''
          package, or `null` if the program is some sort of meta set (in which case it much EXPLICITLY be set null).
        '';
        default =
          let
            pkgPath = splitString "." name;
          in
            # package can be inferred by the attr name, allowing shorthand like
            #   `sane.programs.nano.enable = true;`
            # this indexing will throw if the package doesn't exist and the user forgets to specify
            # a valid source explicitly.
            getAttrFromPath pkgPath pkgs;
      };
      enableFor.system = mkOption {
        type = types.bool;
        default = defaultEnables."${name}".system;
        description = ''
          place this program on the system PATH
        '';
      };
      enableFor.user = mkOption {
        type = types.attrsOf types.bool;
        default = defaultEnables."${name}".user;
        description = ''
          place this program on the PATH for some specified user(s).
        '';
      };
      enabled = mkOption {
        type = types.bool;
        description = ''
          generated (i.e. read-only) value indicating if the program is enabled either for any user or for the system.
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
      persist = {
        plaintext = mkOption {
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
      fs = mkOption {
        type = types.attrs;
        default = {};
        description = "files to populate when this program is enabled";
      };
      secrets = mkOption {
        type = types.attrsOf types.path;
        default = {};
        description = ''
          fs paths to link to some decrypted secret.
          the secret will have same owner as the user under which the program is enabled.
        '';
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "environment variables to set when this program is enabled";
      };
      configOption = mkOption {
        type = types.raw;
        default = mkOption {
          type = types.submodule {};
          default = {};
        };
        description = ''
          declare any other options the program may be configured with.
          you probably want this to be a submodule.
          the option *definitions* can be set with `sane.programs."foo".config = ...`.
        '';
      };
      config = config.configOption;
    };

    config = {
      enabled = config.enableFor.system || any (en: en) (attrValues config.enableFor.user);
    };
  });
  toPkgSpec = types.coercedTo types.package (p: { package = p; }) pkgSpec;

  configs = mapAttrsToList (name: p: {
    assertions = map (sug: {
      assertion = cfg ? "${sug}";
      message = ''program "${sug}" referenced by "${name}", but not defined'';
    }) p.suggestedPrograms;

    # conditionally add to system PATH and env
    environment = lib.optionalAttrs p.enableFor.system {
      systemPackages = lib.optional (p.package != null) p.package;
      variables = p.env;
    };

    # conditionally add to user(s) PATH
    users.users = mapAttrs (user: en: {
      packages = optional (p.package != null && en) p.package;
    }) p.enableFor.user;

    # conditionally persist relevant user dirs and create files
    sane.users = mapAttrs (user: en: optionalAttrs en {
      inherit (p) persist;
      environment = p.env;
      fs = mkMerge [
        # make every fs entry wanted by system boot:
        (mapAttrs (_path: sane-lib.fs.wanted) p.fs)
        # link every secret into the fs:
        (mapAttrs
          # TODO: user the user's *actual* home directory, don't guess.
          (homePath: _src: sane-lib.fs.wantedSymlinkTo "/run/secrets/home/${user}/${homePath}")
          p.secrets
        )
      ];
    }) p.enableFor.user;

    # make secrets available for each user
    sops.secrets = concatMapAttrs
      (user: en: optionalAttrs en (
        mapAttrs'
          (homePath: src: {
            # TODO: user the user's *actual* home directory, don't guess.
            # XXX: name CAN'T START WITH '/', else sops creates the directories funny.
            # TODO: report this upstream.
            name = "home/${user}/${homePath}";
            value = {
              owner = user;
              sopsFile = src;
              format = "binary";
            };
          })
          p.secrets
      ))
      p.enableFor.user;

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
        assertions = f.assertions;
        environment.systemPackages = f.environment.systemPackages;
        environment.variables = f.environment.variables;
        users.users = f.users.users;
        sane.users = f.sane.users;
        sops.secrets = f.sops.secrets;
      };
    in mkMerge [
      (take (sane-lib.mkTypedMerge take configs))
      {
        # expose the pkgs -- as available to the system -- as a build target.
        system.build.pkgs = pkgs;

        sane.programs = lib.mkMerge [
          # make a program for every (toplevel) package
          (lib.mapAttrs (_pkgName: _pkg: {}) pkgs)

          # do the same for programs in known groups
          (lib.mapAttrs' (pkgName: _pkg: { name = "cacert.${pkgName}"; value = {}; }) pkgs.cacert)
          (lib.mapAttrs' (pkgName: _pkg: { name = "gnome.${pkgName}"; value = {}; }) pkgs.gnome)
          (lib.mapAttrs' (pkgName: _pkg: { name = "libsForQt5.${pkgName}"; value = {}; }) pkgs.libsForQt5)
          (lib.mapAttrs' (pkgName: _pkg: { name = "plasma5Packages.${pkgName}"; value = {}; }) pkgs.plasma5Packages)
          (lib.mapAttrs' (pkgName: _pkg: { name = "python3Packages.${pkgName}"; value = {}; }) pkgs.python3Packages)
          (lib.mapAttrs' (pkgName: _pkg: { name = "sway-contrib.${pkgName}"; value = {}; }) pkgs.sway-contrib)
        ];
      }
    ];
}
