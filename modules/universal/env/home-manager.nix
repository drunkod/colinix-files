# docs:
#   https://rycee.gitlab.io/home-manager/
#   https://rycee.gitlab.io/home-manager/options.html
#   man home-configuration.nix
#

{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.colinsane.home-manager;
  vim-swap-dir = ".cache/vim-swap";
in
{
  options = {
    colinsane.home-manager.enable = mkOption {
      default = false;
      type = types.bool;
    };
    colinsane.home-manager.extraPackages = mkOption {
      default = [ ];
      type = types.listOf types.package;
    };
    colinsane.home-manager.windowManager = mkOption {
      default = {};
      type = types.attrs;
    };
    colinsane.home-manager.programs = mkOption {
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

    colinsane.impermanence.home-dirs = [
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
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    # XXX this weird rename + closure is to get home-manager's `config.lib.file` to exist.
    # see: https://github.com/nix-community/home-manager/issues/589#issuecomment-950474105
    home-manager.users.colin = let sysconfig = config; in { config, ... }: {
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
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = {
        "text/html" = [ "librewolf.desktop" ];
        "x-scheme-handler/http" = [ "librewolf.desktop" ];
        "x-scheme-handler/https" = [ "librewolf.desktop" ];
        "x-scheme-handler/about" = [ "librewolf.desktop" ];
        "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
        "image/png" = [ "org.gnome.gThumb.desktop" ];
      };

      # convenience
      home.file."knowledge".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/knowledge";
      home.file."nixos".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/nixos";

      # nb markdown/personal knowledge manager
      home.file.".nb/knowledge".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/knowledge";
      home.file.".nb/.current".text = "knowledge";
      home.file.".nbrc".text = ''
        # manage with `nb settings`
        export NB_AUTO_SYNC=0
      '';

      # aerc TUI mail client
      xdg.configFile."aerc/accounts.conf".source =
        config.lib.file.mkOutOfStoreSymlink sysconfig.sops.secrets.aerc_accounts.path;

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
	    # treesitter syntax highlighting: https://nixos.wiki/wiki/Tree_sitters
	    # config taken from: https://github.com/i077/system/blob/master/modules/home/neovim/default.nix
	    # this is required for tree-sitter to even highlight
	    ({
	      plugin = (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars));
	      type = "lua";
	      config = ''
                require'nvim-treesitter.configs'.setup {
                  highlight = {
                    enable = true,
                    disable = {}
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

	    " at least don't open files with sections folded by default
	    set nofoldenable

            " horizontal rule under the active line
	    " set cursorline

            " highlight trailing space & related syntax errors (doesn't seem to work??)
            " let c_space_errors=1
            " let python_space_errors=1
	  '';
        };

        firefox = lib.mkIf (sysconfig.colinsane.gui.enable) {
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

      wayland.windowManager = cfg.windowManager;

      home.packages = cfg.extraPackages;
    };
  };
}
