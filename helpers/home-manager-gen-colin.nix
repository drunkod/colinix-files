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
  # TODO: fix "is not of type `GVariant value'"
  # dconf.settings = lib.mkIf (gui == "gnome") {
  #   gnome = {
  #     # control alt-tab behavior
  #     "org/gnome/desktop/wm/keybindings" = {
  #       switch-applications = [ "<Super>Tab" ];
  #       switch-applications-backward=[];
  #       switch-windows=["<Alt>Tab"];
  #       switch-windows-backward=["<Super><Alt>Tab"];
  #     };
  #     # idle power savings
  #     "org/gnome/settings-deamon/plugins/power" = {
  #       idle-brigthness = 50;
  #       sleep-inactive-ac-type = "nothing";
  #       sleep-inactive-battery-timeout = 5400;  # seconds
  #     };
  #     "org/gnome/shell" = {
  #       favorite-apps = [
  #         "org.gnome.Nautilus.desktop"
  #         "firefox.desktop"
  #         "kitty.desktop"
  #         # "org.gnome.Terminal.desktop"
  #       ];
  #     };
  #     "org/gnome/desktop/session" = {
  #       # how long until considering a session idle (triggers e.g. screen blanking)
  #       idle-delay = 900;
  #     };
  #     "org/gnome/desktop/interface" = {
  #       text-scaling-factor = 1.25;
  #     };
  #     "org/gnome/desktop/media-handling" = {
  #       # don't auto-mount inserted media
  #       automount = false;
  #       automount-open = false;
  #     };
  #   };
  # };

  # home.pointerCursor = {
  #   package = pkgs.vanilla-dmz;
  #   name = "Vanilla-DMZ";
  # };

  # taken from https://github.com/srid/nix-config/blob/705a70c094da53aa50cf560179b973529617eb31/nix/home/i3.nix
  xsession.windowManager.i3 = lib.mkIf (gui == "i3") (
  let
    mod = "Mod4";
  in {
    enable = true;
    config = {
      modifier = mod;

      fonts = {
        names = [ "DejaVu Sans Mono" ];
        style = "Bold Semi-Condensed";
        size = 11.0;
      };

      # terminal = "kitty";
      # terminal = "${pkgs.kitty}/bin/kitty";

      keybindings = {
        "${mod}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${mod}+p" = "exec ${pkgs.dmenu}/bin/dmenu_run";
        "${mod}+x" = "exec sh -c '${pkgs.maim}/bin/maim -s | xclip -selection clipboard -t image/png'";
        "${mod}+Shift+x" = "exec sh -c '${pkgs.i3lock}/bin/i3lock -c 222222 & sleep 5 && xset dpms force of'";

        # Focus
        "${mod}+j" = "focus left";
        "${mod}+k" = "focus down";
        "${mod}+l" = "focus up";
        "${mod}+semicolon" = "focus right";

        # Move
        "${mod}+Shift+j" = "move left";
        "${mod}+Shift+k" = "move down";
        "${mod}+Shift+l" = "move up";
        "${mod}+Shift+semicolon" = "move right";

        # multi monitor setup
        # "${mod}+m" = "move workspace to output DP-2";
        # "${mod}+Shift+m" = "move workspace to output DP-5";
      };

      # bars = [
      #   {
      #     position = "bottom";
      #     statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${./i3status-rust.toml}";
      #   }
      # ];
    };
  });

  wayland.windowManager.sway = lib.mkIf (gui == "sway") {
    enable = true;
    wrapperFeatures.gtk = true;
    config = rec {
      terminal = "${pkgs.kitty}/bin/kitty";
      gaps.outer = 5;
      gaps.horizontal = 10;
      gaps.smartGaps = true;  # disable gaps on workspace with only one container
      window.border = 3;  # pixel boundary between windows

      # defaults; required for keybindings decl.
      modifier = "Mod1";
      menu = "${pkgs.dmenu}/bin/dmenu";  # TODO: use wofi?
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      keybindings = {
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+d" = "exec ${menu}";

        "${modifier}+${left}" = "focus left";
        "${modifier}+${down}" = "focus down";
        "${modifier}+${up}" = "focus up";
        "${modifier}+${right}" = "focus right";

        "${modifier}+Left" = "focus left";
        "${modifier}+Down" = "focus down";
        "${modifier}+Up" = "focus up";
        "${modifier}+Right" = "focus right";

        "${modifier}+Shift+${left}" = "move left";
        "${modifier}+Shift+${down}" = "move down";
        "${modifier}+Shift+${up}" = "move up";
        "${modifier}+Shift+${right}" = "move right";

        "${modifier}+Shift+Left" = "move left";
        "${modifier}+Shift+Down" = "move down";
        "${modifier}+Shift+Up" = "move up";
        "${modifier}+Shift+Right" = "move right";

        "${modifier}+b" = "splith";
        "${modifier}+v" = "splitv";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+a" = "focus parent";

        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";

        "${modifier}+Shift+space" = "floating toggle";
        "${modifier}+space" = "focus mode_toggle";

        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";

        "${modifier}+Shift+1" =
          "move container to workspace number 1";
        "${modifier}+Shift+2" =
          "move container to workspace number 2";
        "${modifier}+Shift+3" =
          "move container to workspace number 3";
        "${modifier}+Shift+4" =
          "move container to workspace number 4";
        "${modifier}+Shift+5" =
          "move container to workspace number 5";
        "${modifier}+Shift+6" =
          "move container to workspace number 6";
        "${modifier}+Shift+7" =
          "move container to workspace number 7";
        "${modifier}+Shift+8" =
          "move container to workspace number 8";
        "${modifier}+Shift+9" =
          "move container to workspace number 9";

        "${modifier}+Shift+minus" = "move scratchpad";
        "${modifier}+minus" = "scratchpad show";

        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+e" =
          "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";

        "${modifier}+r" = "mode resize";
      } // {
        # media keys
        XF86MonBrightnessDown = ''exec "${pkgs.brightnessctl}/bin/brightnessctl set 2%-"'';
        XF86MonBrightnessUp = ''exec "${pkgs.brightnessctl}/bin/brightnessctl set +2%"'';

        XF86AudioRaiseVolume = "exec '${pkgs.pulsemixer}/bin/pulsemixer --change-volume +5'";
        XF86AudioLowerVolume = "exec '${pkgs.pulsemixer}/bin/pulsemixer --change-volume -5'";
        XF86AudioMute = "exec '${pkgs.pulsemixer}/bin/pulsemixer --toggle-mute'";

      };
    };
    # TODO: this might not be necessary (try deleting this and the numix-cursor package)
    extraConfig = ''
      seat seat0 xcursor_theme Numix-Cursor 18
    '';
    # extraConfig = ''
    #   seat seat0 xcursor_theme "Vanilla-DMZ" 32
    # '';
    # extraSessionCommands = ''
    #   export XDG_SESSION_TYPE=wayland
    #   export XDG_SESSION_DESKTOP=sway
    #   export XDG_CURRENT_DESKTOP=sway
    # '';
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
    pkgs.mix2nix
    pkgs.netcat
    pkgs.nixpkgs-review
    pkgs.nixUnstable  # TODO: still needed on 22.05?
    # pkgs.nixos-generators
    # pkgs.nettools
    pkgs.nmap
    pkgs.obsidian
    pkgs.parted
    pkgs.pciutils
    # pkgs.ponymix
    pkgs.powertop
    pkgs.pulsemixer
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
    pkgs.chromium
    pkgs.clinfo
    pkgs.gnome.dconf-editor
    pkgs.gnome.nautilus
    pkgs.element-desktop  # broken on phosh
    pkgs.evince  # works on phosh
    pkgs.font-manager
    pkgs.gimp  # broken on phosh
    pkgs.gnome.gnome-maps  # works on phosh
    pkgs.gnome-podcasts
    pkgs.gnome.gnome-terminal  # works on phosh
    pkgs.inkscape
    pkgs.libreoffice-fresh  # XXX colin: maybe don't want this on mobile
    pkgs.mesa-demos
    pkgs.numix-cursor-theme
    pkgs.tdesktop  # broken on phosh
    pkgs.vlc  # works on phosh
    pkgs.xterm  # broken on phosh
  ] else [])
  ++ (if gui == "sway" then
  [
    # TODO: move this to helpers/gui/sway.nix?
    pkgs.swaylock
    pkgs.swayidle
    pkgs.wl-clipboard
    pkgs.mako # notification daemon
    pkgs.dmenu # todo: use wofi?
    # user stuff
    # pkgs.pavucontrol
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
