{ config, lib, sane-lib, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  inherit (config.programs.ccache) cacheDir;
in
{
  options.sane.roles.build-machine = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkMerge [
    {
      nix.settings.extra-sandbox-paths = [ cacheDir ];
    }
    (mkIf config.sane.roles.build-machine {
      # serve packages to other machines that ask for them
      sane.services.nixserve.enable = true;

      # enable cross compilation
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      # nixpkgs.config.allowUnsupportedSystem = true;

      # granular compilation cache
      # docs: <https://nixos.wiki/wiki/CCache>
      # investigate the cache with:
      # - `nix-ccache --show-stats`
      # - `build '.#ccache'
      #   - `sudo CCACHE_DIR=/var/cache/ccache ./result/bin/ccache --show-stats -v`
      # TODO: whitelist `--verbose` in <nixpkgs:nixos/modules/programs/ccache.nix>
      # TODO: configure without compression (leverage fs-level compression), and enable file-clone (i.e. hardlinks)
      programs.ccache.enable = true;
      programs.ccache.cacheDir = "/homeless-shelter/.ccache";
      sane.persist.sys.plaintext = [
        { group = "nixbld"; mode = "0775"; directory = config.programs.ccache.cacheDir; }
      ];
      sane.fs."${cacheDir}/ccache.conf" = sane-lib.fs.wantedText ''
        max_size = 50G
      '';

      nixpkgs.overlays = [
        (self: super: {
          # TODO: if we link /homeless-shelter/.ccache into the nix environment,
          # then maybe we get better use of upstream caches?
          ccacheWrapper = super.ccacheWrapper.override {
            extraConfig = ''
              export CCACHE_DIR="${cacheDir}"
            '';
          };
        })
      ];
      # programs.ccache.packageNames = [
      #   # these have to exist in toplevel package set:
      #   # nixpkgs config creates an overlay which overrides each of these packages to build with ccache
      #   # note a potential bootstrapping problem: if the cache directory above hasn't yet been created, then this blocks deployment.
      #   # solution is to manually disable all these entries on the first deployment
      #   # TODO: distribute these elsewhere; make sure it works on cross-compiled builds
      #   "firefox-esr"
      #   # "qtwebengine"
      #   "webkitgtk"
      # ];
    })
  ];
}
