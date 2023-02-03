{ config, lib, pkgs, ... }:

with lib;
with pkgs;
let
  cfg = config.sane.packages;

  pkgSpec = types.submodule {
    options = {
      pkg = mkOption {
        type = types.package;
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
  };

  toPkgSpec = types.coercedTo types.package (p: { pkg = p; }) pkgSpec;
in
{
  options = {
    # packages to deploy to the user's home
    sane.packages.extraUserPkgs = mkOption {
      default = [ ];
      type = types.listOf toPkgSpec;
    };

    sane.packages.enabledUserPkgs = mkOption {
      default = cfg.extraUserPkgs;
      type = types.listOf toPkgSpec;
      description = "generated from other config options";
    };
  };

  config = {
    sane.user.persist.plaintext = concatLists (map (p: p.dir) cfg.enabledUserPkgs);
    sane.user.persist.private = concatLists (map (p: p.private) cfg.enabledUserPkgs);
  };
}
