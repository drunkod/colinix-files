# docs:
#   https://rycee.gitlab.io/home-manager/
#   https://rycee.gitlab.io/home-manager/options.html
#   man home-configuration.nix
#

{ home-manager, lib, config, pkgs, ... }:

with lib;
let
  cfg = config.colinsane.home-manager;
in
{
  imports = [
    home-manager.nixosModule
  ];

  options = {
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

  config = {
    sops.secrets."colinsane_email_passwd" = {
      owner = config.users.users.colin.name;
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.users.colin = {
      home.stateVersion = "21.11";
      home.username = "colin";
      home.homeDirectory = "/home/colin";

      # XDG defines things like ~/Desktop, ~/Downloads, etc.
      # these clutter the home, so i mostly don't use them.
      xdg.userDirs = {
        enable = true;
        createDirectories = false;  # on headless systems, most xdg dirs are noise
        desktop = "$HOME/.xdg/Desktop";
        documents = "$HOME/src";
        download = "$HOME/tmp";
        music = "$HOME/Music";
        pictures = "$HOME/Pictures";
        publicShare = "$HOME/.xdg/Public";
        templates = "$HOME/.xdg/Templates";
        videos = "$HOME/Videos";
      };

      accounts.email.accounts.colinsane = {
        address = "colin@uninsane.org";
        userName = "colin";
        imap = {
          host = "imap.uninsane.org";
          port = 993;
        };
        smtp = {
          host = "mx.uninsane.org";
          port = 465;
        };
        realName = "Colin Sane";
        passwordCommand = "cat ${config.sops.secrets.colinsane_email_passwd.path}";

        primary = true;

        # mailbox synchronization
        # mbsync = {
        #   enable = true;
        #   create = "maildir";
        # };
        # msmtp.enable = true;  # mail sender
        # notmuch.enable = true;  # indexing; used by himalaya

        # docs: https://github.com/soywod/himalaya
        himalaya.enable = true;  # CLI email client
      };

      programs = {
        home-manager.enable = true;  # this lets home-manager manage dot-files in user dirs, i think

        himalaya.enable = true;  # CLI email client

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
        kitty.enable = true;
        git = {
          enable = true;
          userName = "colin";
          userEmail = "colin@uninsane.org";
        };

        vim = {
          enable = true;
          extraConfig = ''
            " wtf vim project: NOBODY LIKES MOUSE FOR VISUAL MODE
            set mouse-=a
            " copy/paste to system clipboard
            set clipboard=unnamedplus
            " <tab> completion menu settings
            set wildmenu
            set wildmode=longest,list,full
            " highlight all matching searches (using / and ?)
            set hlsearch
            " allow backspace to delete empty lines in insert mode
            set backspace=indent,eol,start
            " built-in syntax highlighting
            syntax enable
            " show line/col number in bottom right
            set ruler
            " highlight trailing space & related syntax errors (does this work?)
            let c_space_errors=1
            let python_space_errors=1
          '';
        };

        firefox = lib.mkIf (config.colinsane.gui.enable) {
          enable = true;

          profiles.default = {
            bookmarks = {
              fed_uninsane.url = "https://fed.uninsane.org/";
              delightful.url = "https://delightful.club/";
              crowdsupply.url = "https://www.crowdsupply.com/";
              linux_phone_apps.url = "https://linuxphoneapps.org/mobile-compatibility/5/";
              mempool.url = "https://jochen-hoenicke.de/queue";
            };
          };

          # firefox profile support seems to be broken :shrug:
          # profiles.other = {
          #   id = 2;
          # };

          # NB: these must be manually enabled in the Firefox settings on first start
          # extensions can be found here: https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/addons.json
          extensions = [
            pkgs.nur.repos.rycee.firefox-addons.bypass-paywalls-clean
            pkgs.nur.repos.rycee.firefox-addons.metamask
            pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
            pkgs.nur.repos.rycee.firefox-addons.sidebery
            pkgs.nur.repos.rycee.firefox-addons.sponsorblock
            pkgs.nur.repos.rycee.firefox-addons.ublock-origin
          ];
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

      home.packages = [
        pkgs.backblaze-b2
        pkgs.btrfs-progs
        pkgs.dig
        pkgs.cryptsetup
        pkgs.duplicity
        pkgs.fatresize
        pkgs.fd
        pkgs.file
        pkgs.gnumake
        pkgs.gptfdisk
        pkgs.hdparm
        pkgs.htop
        pkgs.iftop
        pkgs.inetutils  # for telnet
        pkgs.iotop
        pkgs.iptables
        pkgs.jq
        pkgs.killall
        pkgs.lm_sensors  # for sensors-detect
        pkgs.lsof
        pkgs.mix2nix
        pkgs.netcat
        pkgs.networkmanager
        pkgs.nixpkgs-review
        pkgs.nixUnstable  # TODO: still needed on 22.05?
        # pkgs.nixos-generators
        # pkgs.nettools
        pkgs.nmap
        pkgs.obsidian
        pkgs.openssl
        pkgs.parted
        pkgs.pciutils
        # pkgs.ponymix
        pkgs.powertop
        pkgs.pulsemixer
        pkgs.python3
        pkgs.ripgrep
        pkgs.sane-scripts
        pkgs.smartmontools
        pkgs.snapper
        pkgs.socat
        pkgs.sops
        pkgs.ssh-to-age
        pkgs.sudo
        pkgs.usbutils
        pkgs.wget
        pkgs.wireguard-tools
        pkgs.youtube-dl
        pkgs.zola
      ]
      ++ (if config.colinsane.gui.enable then
      [
        # GUI only
        pkgs.chromium
        pkgs.clinfo
        pkgs.element-desktop  # broken on phosh
        pkgs.evince  # works on phosh
        pkgs.font-manager
        pkgs.gimp  # broken on phosh
        pkgs.gnome.dconf-editor
        pkgs.gnome.file-roller
        pkgs.gnome.gnome-maps  # works on phosh
        pkgs.gnome.nautilus
        pkgs.gnome-podcasts
        pkgs.gnome.gnome-terminal  # works on phosh
        pkgs.inkscape
        pkgs.libreoffice-fresh  # XXX colin: maybe don't want this on mobile
        pkgs.mesa-demos
        pkgs.networkmanagerapplet
        pkgs.playerctl
        pkgs.tdesktop  # broken on phosh
        pkgs.vlc  # works on phosh
        pkgs.whalebird # pleroma client. input is broken on phosh
        pkgs.xterm  # broken on phosh
      ] else [])
      ++ (if config.colinsane.gui.enable && pkgs.system == "x86_64-linux" then
      [
        # x86_64 only
        pkgs.discord
        pkgs.kaiteki  # Pleroma client
        pkgs.gnome.zenity # for kaiteki (it will use qarma, kdialog, or zenity)
        pkgs.signal-desktop
        pkgs.spotify
      ] else [])
      ++ cfg.extraPackages;
    };
  };
}
