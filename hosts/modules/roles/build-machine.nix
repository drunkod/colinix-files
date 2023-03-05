{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;
in
{
  options.sane.roles.build-machine = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf config.sane.roles.build-machine {
    # serve packages to other machines that ask for them
    sane.services.nixserve.enable = true;

    # enable cross compilation
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    # nixpkgs.config.allowUnsupportedSystem = true;

    # granular compilation cache
    # docs: <https://nixos.wiki/wiki/CCache>
    # investigate the cache with `nix-cache --show-stats`
    programs.ccache.enable = true;
    sane.persist.sys.plaintext = [
      { group = "nixbld"; mode = "0775"; directory = config.programs.ccache.cacheDir; }
    ];
    nix.settings.extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
    programs.ccache.packageNames = [
      # these have to exist in toplevel package set:
      # nixpkgs config creates an overlay which overrides each of these packages to build with ccache
      # note a potential bootstrapping problem: if the cache directory above hasn't yet been created, then this blocks deployment.
      # solution is to manually disable all these entries on the first deployment
      # TODO: distribute these elsewhere; make sure it works on cross-compiled builds
      "firefox-esr"
      # "qtwebengine"
      "webkitgtk"
    ];
  };
}
