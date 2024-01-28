{ config, lib, options, pkgs, sane-lib, utils, ... }:
let
  saneCfg = config.sane;
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

  # wrap a package so that its binaries (maybe) run in a sandbox
  wrapPkg = pkgName: { fs, net, persist, sandbox, ... }: package: (
    if !sandbox.enable || sandbox.method == null then
      package
    else
      let
        makeSandboxed = pkgs.callPackage ./make-sandboxed.nix { sane-sandboxed = config.sane.sandboxHelper; };
        vpn = lib.findSingle (v: v.default) null null (builtins.attrValues config.sane.vpn);
      in
        makeSandboxed {
          inherit pkgName package;
          inherit (sandbox) binMap capabilities embedProfile extraConfig method wrapperType;
          vpn = if net == "vpn" then vpn else null;
          allowedHomePaths = builtins.attrNames fs ++ builtins.attrNames persist.byPath ++ sandbox.extraHomePaths;
          allowedRootPaths = [
            "/nix/store"
            "/bin/sh"

            "/etc"  #< especially for /etc/profiles/per-user/$USER/bin
            "/run/current-system"  #< for basics like `ls`, and all this program's `suggestedPrograms` (/run/current-system/sw/bin)
            "/run/wrappers"  #< SUID wrappers, in this case so that firejail can be re-entrant
            # "/bin/sh"  #< to allow `firejail --join=...` (doesn't work)
            "/run/systemd/resolve"  #< to allow reading /etc/resolv.conf, which ultimately symlinks here
            # /run/opengl-driver is a symlink into /nix/store; needed by e.g. mpv
            "/run/opengl-driver"
            "/run/opengl-driver-32"  #< XXX: doesn't exist on aarch64?
            "/run/user"  #< particularly /run/user/$id/wayland-1, pulse, etc.
            "/run/secrets/home"  #< TODO: this could be restricted per-app based on the HOME paths they need
            "/usr/bin/env"
            # /dev/dri/renderD128: requested by wayland-egl (e.g. KOreader, animatch, geary)
            #   but everything seems to gracefully fallback to *something* (MESA software rendering?)
            #   GPU attack surface is *large*: <https://security.stackexchange.com/questions/182501/modern-linux-gpu-driver-security>
            # TODO: restrict /dev/dri to just the applications that actually benefit from it
            # "/dev/dri" "/sys/dev/char" "/sys/devices" (lappy: "/sys/devices/pci0000:00")
          ] ++ sandbox.extraPaths;
        }
  );
  pkgSpec = with lib; types.submodule ({ config, name, ... }: {
    options = {
      packageUnwrapped = mkOption {
        type = types.nullOr types.package;
        description = ''
          package, or `null` if the program is some sort of meta set (in which case it much EXPLICITLY be set null).
        '';
        default =
          let
            pkgPath = lib.splitString "." name;
          in
            # package can be inferred by the attr name, allowing shorthand like
            #   `sane.programs.nano.enable = true;`
            # this indexing will throw if the package doesn't exist and the user forgets to specify
            # a valid source explicitly.
            lib.getAttrFromPath pkgPath pkgs;
      };
      package = mkOption {
        type = types.nullOr types.package;
        description = ''
          assigned internally.
          this is `packageUnwrapped`, but with the binaries possibly wrapped in sandboxing measures.
        '';
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
      mime.priority = mkOption {
        type = types.int;
        default = 100;
        description = ''
          program with the numerically lower priority takes precedence whenever two mime associations overlap.
        '';
      };
      mime.associations = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          mime associations. each entry takes the form of:
            "<mime type>" = "<launcher>.desktop"
          e.g.
          {
            "audio/flac" = "vlc.desktop";
            "application/pdf" = "org.gnome.Evince.desktop";
          }
        '';
      };
      mime.urlAssociations = mkOption {
        # TODO: it'd be cool to have the value part of this be `.desktop` files.
        # mimeo doesn't quite do that well. would need a wrapper script which does `mimeo --desk2field Exec mpv.desktop` to get the command
        # and then interpolate the paths into it (%U)
        type = types.attrsOf types.str;
        default = {};
        description = ''
          map of regex -> command.
          e.g. "^https?://(www.)?youtube.com/watch\?.*v=" = "mpv %U"
        '';
      };
      persist = mkOption {
        type = options.sane.persist.sys.type;
        default = {};
        description = ''
          entries to pass onto `sane.persist.sys` or `sane.user.persist`
          when this program is enabled.
        '';
      };
      fs = mkOption {
        # funny type to allow deferring the option merging down to the layer below
        type = types.attrsOf (types.coercedTo types.attrs (a: [ a ]) (types.listOf types.attrs));
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
      services = mkOption {
        # see: <repo:nixos/nixpkgs:nixos/lib/utils.nix>
        # type = utils.systemdUtils.types.services;
        # map to listOf attrs so that we can allow multiple assigners to the same service
        # w/o worrying about merging at this layer, and defer merging to modules/users instead.
        type = types.attrsOf (types.coercedTo types.attrs (a: [ a ]) (types.listOf types.attrs));
        default = {};
        description = ''
          systemd services to define if this package is enabled.
          currently only defines USER services -- acts as noop for root-enabled packages.

          conventions are similar to `systemd.services` or `sane.users.<user>.services`.
          the type at this level is obscured only to as to allow passthrough to `sane.users` w/ proper option merging
        '';
      };
      slowToBuild = mkOption {
        type = types.bool;
        default = false;
        description = ''
          whether this package is very slow, or has unique dependencies which are very slow to build.
          marking packages like this can be used to achieve faster, but limited, rebuilds/deploys (by omitting the package).
        '';
      };
      net = mkOption {
        type = types.enum [ "clearnet" "vpn" ];
        default = "clearnet";
        description = ''
          how this app should have its network traffic routed.
          - "clearnet" for unsandboxed network.
          - "vpn" to route all traffic over the default VPN.
        '';
      };
      sandbox.method = mkOption {
        type = types.nullOr (types.enum [ "bwrap" "capshonly" "firejail" "landlock" ]);
        default = null;  #< TODO: default to something non-null
        description = ''
          how/whether to sandbox all binaries in the package.
        '';
      };
      sandbox.enable = mkOption {
        type = types.bool;
        default = true;
      };
      sandbox.embedProfile = mkOption {
        type = types.bool;
        default = false;
        description = ''
          whether to embed the sandbox settings (path access, etc) into the wrapped binary that lives in /nix/store (true),
          or to encode only a profile name in the wrapper, and use it to query the settings at runtime (false).

          embedded profile means you have to rebuild the wrapper any time you adjust the sandboxing flags,
          but it also means you can run the program without installing it: helpful for iteration.
        '';
      };
      sandbox.wrapperType = mkOption {
        type = types.enum [ "inplace" "wrappedDerivation" ];
        default = "inplace";
        description = ''
          how to manipulate the `packageUnwrapped` derivation in order to achieve sandboxing.
          - inplace: applies an override to `packageUnwrapped`, so that all `bin/` files are sandboxed,
                     and call into un-sandboxed dot-files within `bin/` (like makeWrapper does).
          - wrappedDerivation: leaves the input derivation unchanged, and creates a _new_ derivation whose
                               binaries wrap the binaries in the original derivation with a sandbox.

          "inplace" is more reliable, but "wrappedDerivation" is more lightweight (doesn't force any rebuilds).
          the biggest gap in "wrappedDerivation" is that it doesn't handle .desktop files; just the binaries.
          "wrappedDerivation" is mostly good for prototyping.
        '';
      };
      sandbox.autodetectCliPaths = mkOption {
        type = types.bool;
        default = false;
        description = ''
          if a CLI argument looks like a PATH, should we add it to the sandbox?
        '';
      };
      sandbox.whitelistPwd = mkOption {
        type = types.bool;
        default = false;
        description = ''
          allow the program full access to whichever directory it was launched from.
        '';
      };
      sandbox.binMap = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          map binName -> sandboxAs.
          for example,
            if the package ships `bin/mpv` and `bin/umpv`, this module might know how to sandbox `mpv` but not `umpv`.
            then set `sandbox.binMap.umpv = "mpv";` to sandbox `bin/umpv` with the same rules as `bin/mpv`
        '';
      };
      sandbox.capabilities = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          list of Linux capabilities the program needs. lowercase, and without the cap_ prefix.
          e.g. sandbox.capabilities = [ "net_admin" "net_raw" ];
        '';
      };
      sandbox.extraPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          additional absolute paths to bind into the sandbox.
        '';
      };
      sandbox.extraHomePaths = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          additional home-relative paths to bind into the sandbox.
        '';
      };
      sandbox.extraConfig = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          extra arguments to pass to the sandbox wrapper.
          example: [
            "--sane-sandbox-firejail-arg"
            "--whitelist=''${HOME}/.ssh"
            "--sane-sandbox-firejail-arg"
            "--keep-dev-shm"
          ]
        '';
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

    config = let
      enabledForUser = builtins.any (en: en) (lib.attrValues config.enableFor.user);
      passesSlowTest = saneCfg.enableSlowPrograms || !config.slowToBuild;
    in {
      enabled = (config.enableFor.system || enabledForUser) && passesSlowTest;
      package = if config.packageUnwrapped == null then
        null
      else
        wrapPkg name config config.packageUnwrapped
        ;
      suggestedPrograms = lib.optionals (config.sandbox.method == "bwrap") [ "bubblewrap" ]
        ++ lib.optionals (config.sandbox.method == "firejail") [ "firejail" ];
      # declare a fs dependency for each secret, but don't specify how to populate it yet.
      #   can't populate it here because it varies per-user.
      # this gets the symlink into the sandbox, but not the actual secret.
      fs = lib.mapAttrs (_homePath: _secretSrc: {}) config.secrets;
    };
  });
  toPkgSpec = with lib; types.coercedTo types.package (p: { package = p; }) pkgSpec;

  configs = lib.mapAttrsToList (name: p: {
    assertions = [
      {
        assertion = !(p.sandbox.enable && p.sandbox.method == null) || !p.enabled || p.package == null || !config.sane.strictSandboxing;
        message = "program ${name} specified no `sandbox.method`; please configure a method, or set sandbox.enable = false.";
      }
      {
        assertion = (p.net == "clearnet") || p.sandbox.method != null;
        message = ''program "${name}" requests net "${p.net}", which requires sandboxing, but sandboxing was disabled'';
      }
    ] ++ builtins.map (sug: {
      assertion = cfg ? "${sug}";
      message = ''program "${sug}" referenced by "${name}", but not defined'';
    }) p.suggestedPrograms;

    system.checks = lib.optionals (p.enabled && p.sandbox.method != null && p.package != null) [
      p.package.passthru.checkSandboxed
    ];
    sane.sandboxProfiles = lib.optionals (p.enabled && p.sandbox.method != null && p.package != null) [
      p.package.passthru.sandboxProfiles
    ];

    # conditionally add to system PATH and env
    environment = lib.optionalAttrs (p.enabled && p.enableFor.system) {
      systemPackages = lib.optional (p.package != null) p.package;
      # sessionVariables are set by PAM, as opposed to environment.variables which goes in /etc/profile
      sessionVariables = p.env;
    };

    # conditionally add to user(s) PATH
    users.users = lib.mapAttrs (user: en: {
      packages = lib.optional (p.package != null && en && p.enabled) p.package;
    }) p.enableFor.user;

    # conditionally persist relevant user dirs and create files
    sane.users = lib.mapAttrs (user: en: lib.optionalAttrs (en && p.enabled) {
      inherit (p) persist;
      services = lib.mapAttrs (_: lib.mkMerge) p.services;
      environment = p.env;
      fs = lib.mkMerge [
        p.fs
        # link every secret into the fs:

        (lib.mapAttrs
          # TODO: user the user's *actual* home directory, don't guess.
          (homePath: _src: sane-lib.fs.wantedSymlinkTo "/run/secrets/home/${user}/${homePath}")
          p.secrets
        )
        # alternative double indirection which may be slightly friendlier to sandboxing:
        #   ~/.config/FOO.secret => ~/.config/secrets/.config/FOO.secret => /run/secrets/home/${user}/.config/FOO.secret
        # whereas /run/secrets/* is unreadable *except* for the leafs, ~/.config/secrets is readable and traversable by $USER.
        # (lib.mapAttrs
        #   # TODO: user the user's *actual* home directory, don't guess.
        #   (homePath: _src: sane-lib.fs.wantedSymlinkTo "/home/${user}/.config/secrets/${homePath}")
        #   p.secrets
        # )
        # (lib.mapAttrs'
        #   (homePath: _src: {
        #     name = ".config/secrets/${homePath}";
        #     value = sane-lib.fs.wantedSymlinkTo "/run/secrets/home/${user}/${homePath}";
        #   })
        #   p.secrets
        # )
      ];
    }) p.enableFor.user;

    # make secrets available for each user
    sops.secrets = lib.concatMapAttrs
      (user: en: lib.optionalAttrs (en && p.enabled) (
        lib.mapAttrs'
          (homePath: src: {
            # TODO: use the user's *actual* home directory, don't guess.
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
  options = with lib; {
    # TODO: consolidate these options under one umbrella attrset
    sane.programs = mkOption {
      type = types.attrsOf toPkgSpec;
      default = {};
    };
    sane.enableSlowPrograms = mkOption {
      type = types.bool;
      default = true;
      description = ''
        whether to ship programs which are uniquely slow to build.
      '';
    };
    sane.sandboxHelper = mkOption {
      type = types.package;
      default = pkgs.callPackage ./sane-sandboxed.nix {
        bubblewrap = cfg.bubblewrap.package;
        firejail = cfg.firejail.package;
      };
      description = ''
        `sane-sandbox` package.
        exposed to facilitate debugging, e.g. `nix build '.#hostConfigs.desko.sane.sandboxHelper'`
      '';
    };
    sane.sandboxProfiles = mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        packages with /share/sane-sandbox profiles indicating how to sandbox their associated package.
        this is mostly an internal implementation detail.
      '';
    };
    sane.strictSandboxing = mkOption {
      type = types.bool;
      default = false;
      description = ''
        whether to require that every `sane.program` explicitly specify its sandbox settings
      '';
    };
  };

  config =
    let
      take = f: {
        assertions = f.assertions;
        environment.systemPackages = f.environment.systemPackages;
        environment.sessionVariables = f.environment.sessionVariables;
        users.users = f.users.users;
        sane.sandboxProfiles = f.sane.sandboxProfiles;
        sane.users = f.sane.users;
        sops.secrets = f.sops.secrets;
        system.checks = f.system.checks;
      };
    in lib.mkMerge [
      (take (sane-lib.mkTypedMerge take configs))
      {
        environment.pathsToLink = [ "/share/sane-sandboxed" ];
        environment.systemPackages = [(
          config.sane.sandboxHelper.withProfiles
            (pkgs.symlinkJoin {
              name = "sane-sandbox-profiles";
              paths = config.sane.sandboxProfiles;
            })
        )];
      }
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
          (lib.mapAttrs' (pkgName: _pkg: { name = "mate.${pkgName}"; value = {}; }) pkgs.mate)
          (lib.mapAttrs' (pkgName: _pkg: { name = "plasma5Packages.${pkgName}"; value = {}; }) pkgs.plasma5Packages)
          (lib.mapAttrs' (pkgName: _pkg: { name = "python3Packages.${pkgName}"; value = {}; }) pkgs.python3Packages)
          (lib.mapAttrs' (pkgName: _pkg: { name = "sane-scripts.${pkgName}"; value = {}; }) pkgs.sane-scripts)
          (lib.mapAttrs' (pkgName: _pkg: { name = "sway-contrib.${pkgName}"; value = {}; }) pkgs.sway-contrib)
        ];
      }
    ];
}
