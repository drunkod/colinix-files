# docs:
#   https://rycee.gitlab.io/home-manager/
#   man home-configuration.nix

{ config, pkgs, ... }:
{

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

  programs.firefox = {
    enable = true;
    # profiles.default = {
    #   settings = {
    #     "browser.urlbar.placeholderName" = "DuckDuckGo";
    #   };
    # };
    # extensions = [
    # ];
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

  dconf.settings = {
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

  # xsession.enable = true;
  # xsession.windowManager.command = "…";


  home.packages = [
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
    pkgs.matrix-synapse
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

    pkgs.clinfo
    pkgs.discord
    pkgs.element-desktop
    pkgs.gnome.dconf-editor
    pkgs.mesa-demos
    pkgs.tdesktop
  ];
}
