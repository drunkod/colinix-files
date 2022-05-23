# docs:
#   https://rycee.gitlab.io/home-manager/
#   man home-configuration.nix

# system is e.g. x86_64-linux
# gui is "gnome", or null
{ lib, pkgs, system, gui, extraPackages ? [] }: {
  home.stateVersion = "21.11";
  home.username = "colin";
  home.homeDirectory = "/home/colin";
  programs.home-manager.enable = true;
  programs.zsh.enable = true;
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
  };

  programs.firefox = lib.mkIf (gui != null) {
    enable = true;
    # empty profile required to allow extensions below
    profiles.default = {
      # settings = {
      #   "browser.urlbar.placeholderName" = "DuckDuckGo";
      # };
    };
    # NB: these must be manually enabled in the Firefox settings on first start
    # extensions can be found here: https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/addons.json
    extensions = [
      pkgs.nur.repos.rycee.firefox-addons.bypass-paywalls-clean
      pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
      pkgs.nur.repos.rycee.firefox-addons.sidebery
      pkgs.nur.repos.rycee.firefox-addons.sponsorblock
      pkgs.nur.repos.rycee.firefox-addons.ublock-origin
    ];
  };

  home.packages = [
    pkgs.btrfs-progs
    pkgs.gnumake
    pkgs.dig
    pkgs.duplicity
    pkgs.fatresize
    pkgs.fd
    pkgs.file
    pkgs.gptfdisk
    pkgs.hdparm
    pkgs.htop
    pkgs.iftop
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
    pkgs.telnet
    pkgs.usbutils
    pkgs.wireguard
    pkgs.zola
  ]
  ++ (if gui != null then
  [
    # GUI only
    pkgs.clinfo
    pkgs.element-desktop
    pkgs.gnome.dconf-editor
    pkgs.mesa-demos
    pkgs.tdesktop
  ] else [])
  ++ (if gui != null && system == "x86_64-linux" then
  [
    # x86_64 only
    pkgs.signal-desktop
    pkgs.spotify
    pkgs.discord
  ] else [])
  ++ extraPackages;
}
