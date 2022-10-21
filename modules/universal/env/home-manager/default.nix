# docs:
#   https://rycee.gitlab.io/home-manager/
#   https://rycee.gitlab.io/home-manager/options.html
#   man home-configuration.nix
#

{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.sane.home-manager;
  # extract package from `extraPackages`
  pkglist = pkgspec: builtins.map (e: e.pkg or e) pkgspec;
  # extract `dir` from `extraPackages`
  dirlist = pkgspec: builtins.concatLists (builtins.map (e: if e ? "dir" then [ e.dir ] else []) pkgspec);
  # extract `persist-files` from `extraPackages`
  persistfileslist = pkgspec: builtins.concatLists (builtins.map (e: if e ? "persist-files" then e.persist-files else []) pkgspec);
  # TODO: dirlist and persistfileslist should be folded
  feeds = import ./feeds.nix { inherit lib; };
in
{
  imports = [
    ./kitty.nix
    ./neovim.nix
    ./zsh.nix
  ];

  options = {
    # packages to deploy to the user's home
    sane.home-manager.extraPackages = mkOption {
      default = [ ];
      # each entry can be either a package, or attrs:
      #   { pkg = package; dir = optional string;
      type = types.listOf (types.either types.package types.attrs);
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

  config = {
    sops.secrets."aerc_accounts" = {
      owner = config.users.users.colin.name;
      sopsFile = ../../../../secrets/universal/aerc_accounts.conf;
      format = "binary";
    };
    sops.secrets."sublime_music_config" = {
      owner = config.users.users.colin.name;
      sopsFile = ../../../../secrets/universal/sublime_music_config.json.bin;
      format = "binary";
    };

    sane.impermanence.home-dirs = [
      "archive"
      "dev"
      "records"
      "ref"
      "tmp"
      "use"
      "Music"
      "Pictures"
      "Videos"
    ] ++ (dirlist cfg.extraPackages);
    sane.impermanence.home-files = persistfileslist cfg.extraPackages;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    # XXX this weird rename + closure is to get home-manager's `config.lib.file` to exist.
    # see: https://github.com/nix-community/home-manager/issues/589#issuecomment-950474105
    home-manager.users.colin = let sysconfig = config; in { config, ... }: {

      # run `home-manager-help` to access manpages
      # or `man home-configuration.nix`
      manual.html.enable = false;  # TODO: set to true later (build failure)
      manual.manpages.enable = false;  # TODO: enable after https://github.com/nix-community/home-manager/issues/3344

      home.packages = pkglist cfg.extraPackages;
      wayland.windowManager = cfg.windowManager;

      home.stateVersion = "21.11";
      home.username = "colin";
      home.homeDirectory = "/home/colin";

      home.activation = {
        initKeyring = {
          after = ["writeBoundary"];
          before = [];
          data = "${../../../../scripts/init-keyring}";
        };
      };

      # XDG defines things like ~/Desktop, ~/Downloads, etc.
      # these clutter the home, so i mostly don't use them.
      xdg.userDirs = {
        enable = true;
        createDirectories = false;  # on headless systems, most xdg dirs are noise
        desktop = "$HOME/.xdg/Desktop";
        documents = "$HOME/dev";
        download = "$HOME/tmp";
        music = "$HOME/Music";
        pictures = "$HOME/Pictures";
        publicShare = "$HOME/.xdg/Public";
        templates = "$HOME/.xdg/Templates";
        videos = "$HOME/Videos";
      };

      # the xdg mime type for a file can be found with:
      # - `xdg-mime query filetype path/to/thing.ext`
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = let
        www = "librewolf.desktop";
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

      # convenience
      home.file."knowledge".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/knowledge";
      home.file."nixos".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/nixos";
      home.file."Videos/servo".source = config.lib.file.mkOutOfStoreSymlink "/mnt/servo-media/Videos";
      home.file."Videos/servo-incomplete".source = config.lib.file.mkOutOfStoreSymlink "/mnt/servo-media/incomplete";
      home.file."Music/servo".source = config.lib.file.mkOutOfStoreSymlink "/mnt/servo-media/Music";

      # nb markdown/personal knowledge manager
      home.file.".nb/knowledge".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/knowledge";
      home.file.".nb/.current".text = "knowledge";
      home.file.".nbrc".text = ''
        # manage with `nb settings`
        export NB_AUTO_SYNC=0
      '';

      # uBlock filter list configuration.
      # specifically, enable the GDPR cookie prompt blocker.
      # data.toOverwrite.filterLists is additive (i.e. it supplements the default filters)
      # this configuration method is documented here:
      # - <https://github.com/gorhill/uBlock/issues/2986#issuecomment-364035002>
      # the specific attribute path is found via scraping ublock code here:
      # - <https://github.com/gorhill/uBlock/blob/master/src/js/storage.js>
      # - <https://github.com/gorhill/uBlock/blob/master/assets/assets.json>
      home.file.".librewolf/managed-storage/uBlock0@raymondhill.net.json".text = ''
        {
         "name": "uBlock0@raymondhill.net",
         "description": "ignored",
         "type": "storage",
         "data": {
            "toOverwrite": "{\"filterLists\": [\"fanboy-cookiemonster\"]}"
         }
        }
      '';
      home.file.".librewolf/librewolf.overrides.cfg".text = ''
        // if we can't query the revocation status of a SSL cert because the issuer is offline,
        // treat it as unrevoked.
        // see: <https://librewolf.net/docs/faq/#im-getting-sec_error_ocsp_server_error-what-can-i-do>
        defaultPref("security.OCSP.require", false);
      '';

      # aerc TUI mail client
      xdg.configFile."aerc/accounts.conf".source =
        config.lib.file.mkOutOfStoreSymlink sysconfig.sops.secrets.aerc_accounts.path;

      # make Discord usable even when client is "outdated"
      xdg.configFile."discord/settings.json".text = ''
      {
        "SKIP_HOST_UPDATE": true
      }
      '';

      # sublime music player
      xdg.configFile."sublime-music/config.json".source =
        config.lib.file.mkOutOfStoreSymlink sysconfig.sops.secrets.sublime_music_config.path;

      xdg.configFile."vlc/vlcrc".text =
      let
        podcastUrls = lib.strings.concatStringsSep "|" (
          builtins.map (feed: feed.url) feeds.podcasts
        );
      in ''
        [podcast]
        podcast-urls=${podcastUrls}
        [core]
        metadata-network-access=0
        [qt]
        qt-privacy-ask=0
      '';

      xdg.configFile."gpodderFeeds.opml".text = with feeds;
        feedsToOpml feeds.podcasts;

      # news-flash RSS viewer
      xdg.configFile."newsflashFeeds.opml".text = with feeds;
        feedsToOpml (feeds.texts ++ feeds.images);

      # gnome feeds RSS viewer
      xdg.configFile."org.gabmus.gfeeds.json".text =
      let
        myFeeds = feeds.texts ++ feeds.images;
      in builtins.toJSON {
        # feed format is a map from URL to a dict,
        #   with dict["tags"] a list of string tags.
        feeds = builtins.foldl' (acc: feed: acc // {
          "${feed.url}".tags = [ feed.cat feed.freq ];
        }) {} myFeeds;
        dark_reader = false;
        new_first = true;
        # windowsize = {
        #   width = 350;
        #   height = 650;
        # };
        max_article_age_days = 90;
        enable_js = false;
        max_refresh_threads = 3;
        # saved_items = {};
        # read_items = [];
        show_read_items = true;
        full_article_title = true;
        # views: "webview", "reader", "rsscont"
        default_view = "rsscont";
        open_links_externally = true;
        full_feed_name = false;
        refresh_on_startup = true;
        tags = lib.lists.unique (
          (builtins.catAttrs "cat" myFeeds) ++ (builtins.catAttrs "freq" myFeeds)
        );
        open_youtube_externally = false;
        media_player = "vlc";  # default: mpv
      };

      programs = {
        home-manager.enable = true;  # this lets home-manager manage dot-files in user dirs, i think

        git = {
          enable = true;
          userName = "colin";
          userEmail = "colin@uninsane.org";

          aliases = { co = "checkout"; };
          extraConfig = {
            # difftastic docs:
            # - <https://difftastic.wilfred.me.uk/git.html>
            diff.tool = "difftastic";
            difftool.prompt = false;
            "difftool \"difftastic\"".cmd = ''${pkgs.difftastic}/bin/difft "$LOCAL" "$REMOTE"'';
            # now run `git difftool` to use difftastic git
          };
        };

        # XXX: although home-manager calls this option `firefox`, we can use other browsers and it still mostly works.
        firefox = lib.mkIf (sysconfig.sane.gui.enable) {
          enable = true;
          package = import ./web-browser.nix pkgs;
        };

        mpv = {
          enable = true;
          config = {
            save-position-on-quit = true;
            keep-open = "yes";
          };
        };

        # "command not found" will cause the command to be searched in nixpkgs
        nix-index.enable = true;
      } // cfg.programs;
    };
  };
}
