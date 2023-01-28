# docs:
#   https://rycee.gitlab.io/home-manager/
#   https://rycee.gitlab.io/home-manager/options.html
#   man home-configuration.nix
#

{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.sane.home-manager;
  # extract `pkg` from `sane.packages.enabledUserPkgs`
  pkg-list = pkgspec: builtins.map (e: e.pkg) pkgspec;
in
{
  options = {
    sane.home-manager.enable = mkOption {
      default = false;
      type = types.bool;
    };
    # attributes to copy directly to home-manager's `wayland.windowManager` option
    sane.home-manager.windowManager = mkOption {
      default = {};
      type = types.attrs;
    };

    # extra attributes to include in home-manager's `programs` option
    sane.home-manager.programs = mkOption {
      default = {};
      type = types.attrs;
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    # XXX this weird rename + closure is to get home-manager's `config.lib.file` to exist.
    # see: https://github.com/nix-community/home-manager/issues/589#issuecomment-950474105
    home-manager.users.colin = let sysconfig = config; in { config, ... }: {

      # run `home-manager-help` to access manpages
      # or `man home-configuration.nix`
      manual.html.enable = false;  # TODO: set to true later (build failure)
      manual.manpages.enable = false;  # TODO: enable after https://github.com/nix-community/home-manager/issues/3344

      home.packages = pkg-list sysconfig.sane.packages.enabledUserPkgs;
      wayland.windowManager = cfg.windowManager;

      home.stateVersion = "21.11";
      home.username = "colin";
      home.homeDirectory = "/home/colin";

      # the xdg mime type for a file can be found with:
      # - `xdg-mime query filetype path/to/thing.ext`
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = let
        www = sysconfig.sane.web-browser.browser.desktop;
        pdf = "org.gnome.Evince.desktop";
        md = "obsidian.desktop";
        thumb = "org.gnome.gThumb.desktop";
        video = "vlc.desktop";
        # audio = "mpv.desktop";
        audio = "vlc.desktop";
      in {
        # HTML
        "text/html" = [ www ];
        "x-scheme-handler/http" = [ www ];
        "x-scheme-handler/https" = [ www ];
        "x-scheme-handler/about" = [ www ];
        "x-scheme-handler/unknown" = [ www ];
        # RICH-TEXT DOCUMENTS
        "application/pdf" = [ pdf ];
        "text/markdown" = [ md ];
        # IMAGES
        "image/heif" = [ thumb ];  # apple codec
        "image/png" = [ thumb ];
        "image/jpeg" = [ thumb ];
        # VIDEO
        "video/mp4" = [ video ];
        "video/quicktime" = [ video ];
        "video/x-matroska" = [ video ];
        # AUDIO
        "audio/flac" = [ audio ];
        "audio/mpeg" = [ audio ];
        "audio/x-vorbis+ogg" = [ audio ];
      };

      programs = lib.mkMerge [
        {
          home-manager.enable = true;  # this lets home-manager manage dot-files in user dirs, i think
          # "command not found" will cause the command to be searched in nixpkgs
          nix-index.enable = true;
        }
        cfg.programs
      ];
    };
  };
}
