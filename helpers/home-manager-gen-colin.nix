# docs:
#   https://rycee.gitlab.io/home-manager/
#   https://rycee.gitlab.io/home-manager/options.html
#   man home-configuration.nix
#

# system is e.g. x86_64-linux
# gui is "gnome", or null
{ lib, pkgs, system, gui, extraPackages ? [] }: {
  home.stateVersion = "21.11";
  home.username = "colin";
  home.homeDirectory = "/home/colin";
  programs.home-manager.enable = true;  # this lets home-manager manage dot-files in user dirs, i think

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

  programs.zsh = {
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
  programs.kitty.enable = true;
  programs.git = {
    enable = true;
    userName = "colin";
    userEmail = "colin@uninsane.org";
  };

  programs.vim = {
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

  # obtain these by running `dconf dump /` after manually customizing gnome
  dconf.settings = lib.mkIf (gui == "gnome") {
    # control alt-tab behavior
    "org/gnome/desktop/wm/keybindings" = {
      switch-applications = [ "<Super>Tab" ];
      switch-applications-backward=[];
      switch-windows=["<Alt>Tab"];
      switch-windows-backward=["<Super><Alt>Tab"];
    };
    # idle power savings
    "org/gnome/settings-deamon/plugins/power" = {
      idle-brigthness = 50;
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-timeout = 5400;  # seconds
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "kitty.desktop"
        # "org.gnome.Terminal.desktop"
      ];
    };
    "org/gnome/desktop/session" = {
      # how long until considering a session idle (triggers e.g. screen blanking)
      idle-delay = 900;
    };
    "org/gnome/desktop/interface" = {
      text-scaling-factor = 1.25;
    };
    "org/gnome/desktop/media-handling" = {
      # don't auto-mount inserted media
      automount = false;
      automount-open = false;
    };
  };

  programs.firefox = lib.mkIf (gui != null) {
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

  home.shellAliases = {
    ":q" = "exit";
    # common typos
    "cd.." = "cd ..";
    "cd../" = "cd ../";
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  home.packages = [
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
    pkgs.pciutils
    pkgs.mix2nix
    pkgs.netcat
    pkgs.nixUnstable
    # pkgs.nixos-generators
    # pkgs.nettools
    pkgs.nmap
    pkgs.parted
    pkgs.powertop
    pkgs.python3
    pkgs.ripgrep
    pkgs.smartmontools
    pkgs.snapper
    pkgs.socat
    pkgs.sudo
    pkgs.usbutils
    pkgs.wireguard-tools
    pkgs.zola
  ]
  ++ (if gui != null then
  [
    # GUI only
    pkgs.clinfo
    pkgs.element-desktop  # broken on phosh
    pkgs.evince  # works on phosh
    pkgs.gimp  # broken on phosh
    pkgs.gnome.gnome-maps  # works on phosh
    pkgs.gnome.gnome-terminal  # works on phosh
    pkgs.libreoffice-fresh  # XXX colin: maybe don't want this on mobile
    pkgs.mesa-demos
    pkgs.tdesktop  # broken on phosh
    pkgs.vlc  # broken on phosh
    pkgs.xterm  # broken on phosh
  ] else [])
  ++ (if gui == "gnome" then
  [
    pkgs.gnome.dconf-editor
  ] else [])
  ++ (if gui != null && system == "x86_64-linux" then
  [
    # x86_64 only
    pkgs.signal-desktop
    pkgs.spotify
    pkgs.discord
    # pleroma client. TODO: port kaiteki to nix: https://craftplacer.moe/projects/kaiteki/
    pkgs.whalebird
  ] else [])
  ++ extraPackages;
}
