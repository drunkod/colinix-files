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
      sopsFile = ../../secrets/universal/aerc_accounts.conf;
      format = "binary";
    };

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

      # convenience
      home.file."knowledge".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/knowledge";
      home.file."nixos".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/nixos";

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
          settings.enable_audio_bell = false;
        };
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

        firefox = lib.mkIf (sysconfig.colinsane.gui.enable) {
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
          extensions = let
            addons = pkgs.nur.repos.rycee.firefox-addons;
          in [
            addons.bypass-paywalls-clean
            addons.metamask
            addons.i-dont-care-about-cookies
            addons.sidebery
            addons.sponsorblock
            addons.ublock-origin
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

      # devtools:
      # bison
      # dtc
      # flex
      # gcc-arm-embedded
      # gcc_multi
      # swig

      home.packages = with pkgs; [
        backblaze-b2
        btrfs-progs
        cryptsetup
        dig
        duplicity
        efibootmgr
        fatresize
        fd
        file
        gnumake
        gptfdisk
        hdparm
        htop
        iftop
        ifuse
        inetutils  # for telnet
        iotop
        ipfs
        iptables
        jq
        killall
        libimobiledevice
        lm_sensors  # for sensors-detect
        lsof
        mix2nix
        netcat
        nethogs
        networkmanager
        nixpkgs-review
        # nixos-generators
        # nettools
        nmap
        oathToolkit  # for oathtool
        openssl
        parted
        pciutils
        # ponymix
        powertop
        pulsemixer
        python3
        ripgrep
        rmlint
        sane-scripts
        smartmontools
        snapper
        socat
        sops
        ssh-to-age
        sudo
        usbutils
        wget
        wireguard-tools
        youtube-dl
        zola
      ]
      ++ (if sysconfig.colinsane.gui.enable then
      with pkgs;
      [
        # GUI only
        aerc  # email client
        audacity
        chromium
        clinfo
        element-desktop  # broken on phosh
        evince  # works on phosh
        font-manager
        gimp  # broken on phosh
        gnome.dconf-editor
        gnome-feeds  # RSS reader (with claimed mobile support)
        gnome.file-roller
        gnome.gnome-maps  # works on phosh
        gnome.nautilus
        gnome-podcasts
        gnome.gnome-terminal  # works on phosh
        inkscape
        libreoffice-fresh  # XXX colin: maybe don't want this on mobile
        mesa-demos
        networkmanagerapplet
        obsidian
        playerctl
        tdesktop  # broken on phosh
        vlc  # works on phosh
        whalebird # pleroma client. input is broken on phosh
        xterm  # broken on phosh
      ] else [])
      ++ (if sysconfig.colinsane.gui.enable && pkgs.system == "x86_64-linux" then
      with pkgs;
      [
        # x86_64 only
        discord
        kaiteki  # Pleroma client
        gnome.zenity # for kaiteki (it will use qarma, kdialog, or zenity)
        signal-desktop
        spotify
      ] else [])
      ++ cfg.extraPackages;
    };
  };
}
