# docs:
#   https://rycee.gitlab.io/home-manager/
#   https://rycee.gitlab.io/home-manager/options.html
#   man home-configuration.nix
#

{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.sane.home-manager;
  vim-swap-dir = ".cache/vim-swap";
  # extract package from `extraPackages`
  pkglist = pkgspec: builtins.map (e: e.pkg or e) pkgspec;
  # extract `dir` from `extraPackages`
  dirlist = pkgspec: builtins.concatLists (builtins.map (e: if e ? "dir" then [ e.dir ] else []) pkgspec);
  # extract `persist-files` from `extraPackages`
  persistfileslist = pkgspec: builtins.concatLists (builtins.map (e: if e ? "persist-files" then e.persist-files else []) pkgspec);
  # TODO: dirlist and persistfileslist should be folded
in
{
  options = {
    sane.home-manager.enable = mkOption {
      default = false;
      type = types.bool;
    };

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

  config = lib.mkIf cfg.enable {
    sops.secrets."aerc_accounts" = {
      owner = config.users.users.colin.name;
      sopsFile = ../../../secrets/universal/aerc_accounts.conf;
      format = "binary";
    };
    sops.secrets."sublime_music_config" = {
      owner = config.users.users.colin.name;
      sopsFile = ../../../secrets/universal/sublime_music_config.json.bin;
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
      vim-swap-dir
    ] ++ (dirlist cfg.extraPackages);
    sane.impermanence.home-files = persistfileslist cfg.extraPackages;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    # XXX this weird rename + closure is to get home-manager's `config.lib.file` to exist.
    # see: https://github.com/nix-community/home-manager/issues/589#issuecomment-950474105
    home-manager.users.colin = let sysconfig = config; in { config, ... }: {

      home.packages = pkglist cfg.extraPackages;
      wayland.windowManager = cfg.windowManager;

      home.stateVersion = "21.11";
      home.username = "colin";
      home.homeDirectory = "/home/colin";

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
      xdg.mimeApps.defaultApplications = {
        # HTML
        "text/html" = [ "librewolf.desktop" ];
        "x-scheme-handler/http" = [ "librewolf.desktop" ];
        "x-scheme-handler/https" = [ "librewolf.desktop" ];
        "x-scheme-handler/about" = [ "librewolf.desktop" ];
        "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
        # RICH-TEXT DOCUMENTS
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "text/markdown" = [ "obsidian.desktop" ];
        # IMAGES
        "image/heif" = [ "org.gnome.gThumb.desktop" ];  # apple codec
        "image/png" = [ "org.gnome.gThumb.desktop" ];
        "image/jpeg" = [ "org.gnome.gThumb.desktop" ];
        # VIDEO
        "video/mp4" = [ "vlc.desktop" ];
        "video/quicktime" = [ "vlc.desktop" ];
        "video/x-matroska" = [ "vlc.desktop" ];
        # AUDIO
        "audio/flag" = [ "vlc.desktop" ];
        "audio/mpeg" = [ "vlc.desktop" ];
        "audio/x-vorbis+ogg" = [ "vlc.desktop" ];
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
        podcastUrls = lib.strings.concatStringsSep "|" sysconfig.sane.feeds.podcastUrls;
      in ''
      [podcast]
      podcast-urls=${podcastUrls}
      [core]
      metadata-network-access=0
      [qt]
      qt-privacy-ask=0
      '';
      xdg.configFile."gpodderFeeds.opml".text =
      let
        entries = builtins.toString (builtins.map
          (url: ''\n    <outline xmlUrl="${url}" type="rss"/>'')
          sysconfig.sane.feeds.podcastUrls
        );
      in ''
        <?xml version="1.0" encoding="utf-8"?>
        <opml version="2.0">
          <body>${entries}
          </body>
        </opml>
      '';

      # gnome feeds RSS viewer
      xdg.configFile."org.gabmus.gfeeds.json".text = builtins.toJSON {
        feeds = {
          # AGGREGATORS (> 1 post/day)
          "https://www.lesswrong.com/feed.xml" = { tags = [ "hourly" "rat" ]; };
          "http://www.econlib.org/index.xml" = { tags = [ "hourly" "pol" ]; };
          # AGGREGATORS (< 1 post/day)
          "https://palladiummag.com/feed" = { tags = [ "weekly" "uncat" ]; };
          "https://profectusmag.com/feed" = { tags = [ "weekly" "uncat" ]; };

          "https://semiaccurate.com/feed" = { tags = [ "weekly" "tech" ]; };
          "https://linuxphoneapps.org/blog/atom.xml" = { tags = [ "infrequent" "tech" ]; };
          "https://spectrum.ieee.org/rss" = { tags = [ "weekly" "tech" ]; };

          ## No Moods, Ads or Cutesy Fucking Icons
          "https://www.rifters.com/crawl/?feed=rss2" = { tags = [ "weekly" "uncat" ]; };

          # DEVELOPERS
          "https://mg.lol/blog/rss/" = { tags = [ "infrequent" "tech" ]; };
          ## Ken Shirriff
          "https://www.righto.com/feeds/posts/default" = { tags = [ "infrequent" "tech" ]; };
          ## Vitalik Buterin
          "https://vitalik.ca/feed.xml" = { tags = [ "infrequent" "tech" ]; };
          ## ian (Sanctuary)
          "https://sagacioussuricata.com/feed.xml" = { tags = [ "infrequent" "tech" ]; };
          ## Bunnie Juang
          "https://www.bunniestudios.com/blog/?feed=rss2" = { tags = [ "infrequent" "tech" ]; };
          "https://blog.danieljanus.pl/atom.xml" = { tags = [ "infrequent" "tech" ]; };
          "https://ianthehenry.com/feed.xml" = { tags = [ "infrequent" "tech" ]; };
          "https://bitbashing.io/feed.xml" = { tags = [ "infrequent" "tech" ]; };
          "https://idiomdrottning.org/feed.xml" = { tags = [ "daily" "uncat" ]; };

          # (TECH; POL) COMMENTATORS
          "http://benjaminrosshoffman.com/feed" = { tags = [ "weekly" "pol" ]; };
          ## Ben Thompson
          "https://www.stratechery.com/rss" = { tags = [ "weekly" "pol" ]; };
          ## Balaji
          "https://balajis.com/rss" = { tags = [ "weekly" "pol" ]; };
          "https://www.ben-evans.com/benedictevans/rss.xml" = { tags = [ "weekly" "pol" ]; };
          "https://www.lynalden.com/feed" = { tags = [ "infrequent" "pol" ]; };
          "https://austinvernon.site/rss.xml" = { tags = [ "infrequent" "tech" ]; };
          "https://oversharing.substack.com/feed" = { tags = [ "daily" "pol" ]; };
          ## David Rosenthal
          "https://blog.dshr.org/rss.xml" = { tags = [ "weekly" "pol" ]; };
          ## Matt Levine
          "https://www.bloomberg.com/opinion/authors/ARbTQlRLRjE/matthew-s-levine.rss" = { tags = [ "weekly" "pol" ]; };

          # RATIONALITY/PHILOSOPHY/ETC
          "https://samkriss.substack.com/feed" = { tags = [ "infrequent" "uncat" ]; };  # ... satire? phil?
          "https://unintendedconsequenc.es/feed" = { tags = [ "infrequent" "rat" ]; };

          "https://applieddivinitystudies.com/atom.xml" = { tags = [ "weekly" "rat" ]; };
          "https://slimemoldtimemold.com/feed.xml" = { tags = [ "weekly" "rat" ]; };

          "https://www.richardcarrier.info/feed" = { tags = [ "weekly" "rat" ]; };
          "https://www.gwern.net/feed.xml" = { tags = [ "infrequent" "uncat" ]; };

          ## Jason Crawford
          "https://rootsofprogress.org/feed.xml" = { tags = [ "weekly" "rat" ]; };
          ## Robin Hanson
          "https://www.overcomingbias.com/feed" = { tags = [ "daily" "rat" ]; };
          ## Scott Alexander
          "https://astralcodexten.substack.com/feed.xml" = { tags = [ "daily" "rat" ]; };
          ## Paul Christiano
          "https://sideways-view.com/feed" = { tags = [ "infrequent" "rat" ]; };
          ## Sean Carroll
          "https://www.preposterousuniverse.com/rss" = { tags = [ "infrequent" "rat" ]; };

          # COMICS
          "https://www.smbc-comics.com/comic/rss" = { tags = [ "daily" "visual" ]; };
          "https://xkcd.com/atom.xml" = { tags = [ "daily" "visual" ]; };
          "http://dilbert.com/feed" = { tags = ["daily" "visual" ]; };

          # ART
          "https://miniature-calendar.com/feed" = { tags = [ "daily" "visual" ]; };

          # CODE
          "https://github.com/Kaiteki-Fedi/Kaiteki/commits/master.atom" = { tags = [ "infrequent" "tech" ]; };
        };
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
        tags = [
          # hourly => aggregator
          # daily => prolifiq writer
          # weekly => i can keep up with most -- but maybe not all -- of their content
          # infrequent => i can read everything in this category
          "hourly" "daily" "weekly" "infrequent"
          # rat[ionality] gets used interchangably with philosophy, here.
          # pol[itical] gets used for social commentary and economics as well.
          # visual gets used for comics/art
          "uncat" "rat" "tech" "pol" "visual"
        ];
        open_youtube_externally = false;
        media_player = "vlc";  # default: mpv
      };

      programs = {
        home-manager.enable = true;  # this lets home-manager manage dot-files in user dirs, i think

        zsh = {
          enable = true;
          enableSyntaxHighlighting = true;
          enableVteIntegration = true;
          dotDir = ".config/zsh";

          initExtraBeforeCompInit = ''
            # p10k instant prompt
            # run p10k configure to configure, but it can't write out its file :-(
            POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
          '';

          # prezto = oh-my-zsh fork; controls prompt, auto-completion, etc.
          # see: https://github.com/sorin-ionescu/prezto
          prezto = {
            enable = true;
            pmodules = [
              "environment"
              "terminal"
              "editor"
              "history"
              "directory"
              "spectrum"
              "utility"
              "completion"
              "prompt"
              "git"
            ];
            prompt = {
              theme = "powerlevel10k";
            };
          };
        };
        kitty = {
          enable = true;
          # docs: https://sw.kovidgoyal.net/kitty/conf/
          settings = {
            # disable terminal bell (when e.g. you backspace too many times)
            enable_audio_bell = false;
          };
          keybindings = {
            "ctrl+n" = "new_os_window_with_cwd";
          };
          # docs: https://github.com/kovidgoyal/kitty-themes
          # theme = "1984 Light";  # dislike: awful, harsh blues/teals
          # theme = "Adventure Time";  # dislike: harsh (dark)
          # theme = "Atom One Light";  # GOOD: light theme. all color combos readable. not a huge fan of the blue.
          # theme = "Belafonte Day";  # dislike: too low contrast for text colors
          # theme = "Belafonte Night";  # better: dark theme that's easy on the eyes. all combos readable. low contrast.
          # theme = "Catppuccin";  # dislike: a bit pale/low-contrast (dark)
          # theme = "Desert";  # mediocre: colors are harsh
          # theme = "Earthsong";  # BEST: dark theme. readable, good contrast. unique, but decent colors.
          # theme = "Espresso Libre";  # better: dark theme. readable, but meh colors
          # theme = "Forest Night";  # decent: very pastel. it's workable, but unconventional and muted/flat.
          # theme = "Gruvbox Material Light Hard";  # mediocre light theme.
          # theme = "kanagawabones";  # better: dark theme. colors are too background-y
          # theme = "Kaolin Dark";  # dislike: too dark
          # theme = "Kaolin Breeze";  # mediocre: not-too-harsh light theme, but some parts are poor contrast
          # theme = "Later This Evening";  # mediocre: not-too-harsh dark theme, but cursor is poor contrast
          # theme = "Material"; # decent: light theme, few colors.
          # theme = "Mayukai";  # decent: not-too-harsh dark theme. the teal is a bit straining
          # theme = "Nord";  # mediocre: pale background, low contrast
          # theme = "One Half Light";  # better: not-too-harsh light theme. contrast could be better
          theme = "PaperColor Dark";  # BEST: dark theme, very readable still the colors are background-y
          # theme = "Parasio Dark";  # dislike: too low contrast
          # theme = "Pencil Light";  # better: not-too-harsh light theme. decent contrast.
          # theme = "Pnevma";  # dislike: too low contrast
          # theme = "Piatto Light";  # better: readable light theme. pleasing colors. powerline prompt is hard to read.
          # theme = "Rosé Pine Dawn";  # GOOD: light theme. all color combinations are readable. it is very mild -- may need to manually tweak contrast. tasteful colors
          # theme = "Rosé Pine Moon";  # GOOD: dark theme. tasteful colors. but background is a bit intense
          # theme = "Sea Shells";  # mediocre. not all color combos are readable
          # theme = "Solarized Light";  # mediocre: not-too-harsh light theme; GREAT background; but some colors are low contrast
          # theme = "Solarized Dark Higher Contrast";  # better: dark theme, decent colors
          # theme = "Sourcerer";  # mediocre: ugly colors
          # theme = "Space Gray";  # mediocre: too muted
          # theme = "Space Gray Eighties";  # better: all readable, decent colors
          # theme = "Spacemacs";  # mediocre: too muted
          # theme = "Spring";  # mediocre: readable light theme, but the teal is ugly.
          # theme = "Srcery";  # better: highly readable. colors are ehhh
          # theme = "Substrata";  # decent: nice colors, but a bit flat.
          # theme = "Sundried";  # mediocre: the solar text makes me squint
          # theme = "Symfonic";  # mediocre: the dark purple has low contrast to the black bg.
          # theme = "Tango Light";  # dislike: teal is too grating
          # theme = "Tokyo Night Day";  # medicore: too muted
          # theme = "Tokyo Night";  # better: tasteful. a bit flat
          # theme = "Tomorrow";  # GOOD: all color combinations are readable. contrast is slightly better than Rose. on the blander side
          # theme = "Treehouse";  # dislike: the orange is harsh on my eyes.
          # theme = "Urple";  # dislike: weird palette
          # theme = "Warm Neon";  # decent: not-too-harsh dark theme. the green is a bit unattractive
          # theme = "Wild Cherry";  # GOOD: dark theme: nice colors. a bit flat
          # theme = "Xcodedark";  # dislike: bad palette
          # theme = "citylights";  # decent: dark theme. some parts have just a bit low contrast
          # theme = "neobones_light"; # better light theme. the background is maybe too muted
          # theme = "vimbones";
          # theme = "zenbones_dark";  # mediocre: readable, but meh colors
          # theme = "zenbones_light";  # decent: light theme. all colors are readable. contrast is passable but not excellent. highlight color is BAD
          # theme = "zenwritten_dark";  # mediocre: looks same as zenbones_dark
          # extraConfig = "";
        };
        git = {
          enable = true;
          userName = "colin";
          userEmail = "colin@uninsane.org";
        };

        neovim = {
          # neovim: https://github.com/neovim/neovim
          enable = true;
          viAlias = true;
          vimAlias = true;
          plugins = with pkgs.vimPlugins; [
            # docs: surround-nvim: https://github.com/ur4ltz/surround.nvim/
            # docs: vim-surround: https://github.com/tpope/vim-surround
            vim-surround
            # docs: fzf-vim (fuzzy finder): https://github.com/junegunn/fzf.vim
            fzf-vim
            # docs: https://github.com/KeitaNakamura/tex-conceal.vim/
            ({
              plugin = tex-conceal-vim;
              type = "viml";
              config = ''
                " present prettier fractions
                let g:tex_conceal_frac=1
              '';
            })
            ({
              plugin = vim-SyntaxRange;
              type = "viml";
              config = ''
                " enable markdown-style codeblock highlighting for tex code
                autocmd BufEnter * call SyntaxRange#Include('```tex', '```', 'tex', 'NonText')
                " autocmd Syntax tex set conceallevel=2
              '';
            })
            # nabla renders inline math in any document, but it's buggy.
            #   https://github.com/jbyuki/nabla.nvim
            # ({
            #   plugin = pkgs.nabla;
            #   type = "lua";
            #   config = ''
            #     require'nabla'.enable_virt()
            #   '';
            # })
            # treesitter syntax highlighting: https://nixos.wiki/wiki/Tree_sitters
            # docs: https://github.com/nvim-treesitter/nvim-treesitter
            # config taken from: https://github.com/i077/system/blob/master/modules/home/neovim/default.nix
            # this is required for tree-sitter to even highlight
            ({
              plugin = (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars));
              type = "lua";
              config = ''
                require'nvim-treesitter.configs'.setup {
                  highlight = {
                    enable = true,
                    -- disable treesitter on Rust so that we can use SyntaxRange
                    -- and leverage TeX rendering in rust projects
                    disable = { "rust", "tex", "latex" },
                    -- disable = { "tex", "latex" },
                    -- true to also use builtin vim syntax highlighting when treesitter fails
                    additional_vim_regex_highlighting = false
                  },
                  incremental_selection = {
                    enable = true,
                    keymaps = {
                      init_selection = "gnn",
                      node_incremental = "grn",
                      mcope_incremental = "grc",
                      node_decremental = "grm"
                    }
                  },
                  indent = {
                    enable = true,
                    disable = {}
                  }
                }

                vim.o.foldmethod = 'expr'
                vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
              '';
            })
          ];
          extraConfig = ''
            " copy/paste to system clipboard
            set clipboard=unnamedplus

            " screw tabs; always expand them into spaces
            set expandtab

            " at least don't open files with sections folded by default
            set nofoldenable

            " allow text substitutions for certain glyphs.
            " higher number = more aggressive substitution (0, 1, 2, 3)
            " i only make use of this for tex, but it's unclear how to
            " apply that *just* to tex and retain the SyntaxRange stuff.
            set conceallevel=2

            " horizontal rule under the active line
            " set cursorline

            " highlight trailing space & related syntax errors (doesn't seem to work??)
            " let c_space_errors=1
            " let python_space_errors=1

            " enable highlighting of leading/trailing spaces,
            " and especially tabs
            " source: https://www.reddit.com/r/neovim/comments/chlmfk/highlight_trailing_whitespaces_in_neovim/
            set list
            set listchars=tab:▷\·,trail:·,extends:◣,precedes:◢,nbsp:○
          '';
        };

        # XXX: although home-manager calls this option `firefox`, we can use other browsers and it still mostly works.
        firefox = lib.mkIf (sysconfig.sane.gui.enable) {
          enable = true;
          package = import ./web-browser.nix pkgs;
        };

        # "command not found" will cause the command to be searched in nixpkgs
        nix-index.enable = true;
      } // cfg.programs;

      home.shellAliases = {
        ":q" = "exit";
        # common typos
        "cd.." = "cd ..";
        "cd../" = "cd ../";
      };
    };
  };
}
