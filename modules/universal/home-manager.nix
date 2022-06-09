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
  };

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.users.colin = {
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

      programs.firefox = lib.mkIf (config.colinsane.gui.enable) {
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

      # "command not found" will cause the command to be searched in nixpkgs
      programs.nix-index.enable = true;

      # TODO: move this to sway.nix
      wayland.windowManager.sway = lib.mkIf (config.colinsane.gui.sway.enable) {
        enable = true;
        wrapperFeatures.gtk = true;
        config = rec {
          terminal = "${pkgs.kitty}/bin/kitty";
          window.border = 3;  # pixel boundary between windows

          # defaults; required for keybindings decl.
          modifier = "Mod1";
          # list of launchers: https://www.reddit.com/r/swaywm/comments/v39hxa/your_favorite_launcher/
          # menu = "${pkgs.dmenu}/bin/dmenu_path";
          menu = "${pkgs.fuzzel}/bin/fuzzel";
          # menu = "${pkgs.albert}/bin/albert";
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

            "${modifier}+Print" = "exec '${pkgs.sway-contrib.grimshot}/bin/grimshot copy area'";
          };

          # mostly defaults:
          bars = [{
            mode = "dock";
            hiddenState = "hide";
            position = "top";
            command = "${pkgs.waybar}/bin/waybar";
            workspaceButtons = true;
            workspaceNumbers = true;
            statusCommand = "${pkgs.i3status}/bin/i3status";
            fonts = {
              # names = [ "monospace" "Noto Color Emoji" ];
              # size = 8.0;
              # names = [ "Font Awesome 6 Free" "DejaVu Sans" "Hack" ];
              names = with config.fonts.fontconfig.defaultFonts; (emoji ++ monospace ++ serif ++ sansSerif);
              size = 24.0;
            };
            trayOutput = "primary";
            colors = {
              background = "#000000";
              statusline = "#ffffff";
              separator = "#666666";
              focusedWorkspace = {
                border = "#4c7899";
                background = "#285577";
                text = "#ffffff";
              };
              activeWorkspace = {
                border = "#333333";
                background = "#5f676a";
                text = "#ffffff";
              };
              inactiveWorkspace = {
                border = "#333333";
                background = "#222222";
                text = "#888888";
              };
              urgentWorkspace = {
                border = "#2f343a";
                background = "#900000";
                text = "#ffffff";
              };
              bindingMode = {
                border = "#2f343a";
                background = "#900000";
                text = "#ffffff";
              };
            };
          }];
        };
      };

      programs.waybar = lib.mkIf (config.colinsane.gui.sway.enable) {
        enable = true;
        # docs: https://github.com/Alexays/Waybar/wiki/Configuration
        settings = {
          mainBar = {
            layer = "top";
            height = 40;
            modules-left = ["sway/workspaces" "sway/mode"];
            modules-center = ["sway/window"];
            modules-right = ["custom/mediaplayer" "clock" "cpu" "network"];
            "sway/window" = {
              max-length = 50;
            };
            # include song artist/title. source: https://www.reddit.com/r/swaywm/comments/ni0vso/waybar_spotify_tracktitle/
            "custom/mediaplayer" = {
              exec = pkgs.writeShellScript "waybar-mediaplayer" ''
                player_status=$(${pkgs.playerctl}/bin/playerctl status 2> /dev/null)
                if [ "$player_status" = "Playing" ]; then
                  echo "$(${pkgs.playerctl}/bin/playerctl metadata artist) - $(${pkgs.playerctl}/bin/playerctl metadata title)"
                elif [ "$player_status" = "Paused" ]; then
                  echo " $(${pkgs.playerctl}/bin/playerctl metadata artist) - $(${pkgs.playerctl}/bin/playerctl metadata title)"
                fi
              '';
              interval = 2;
              format = "{}  ";
              # return-type = "json";
              on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
              on-scroll-up = "${pkgs.playerctl}/bin/playerctl next";
              on-scroll-down = "${pkgs.playerctl}/bin/playerctl previous";
            };
            network = {
              interval = 1;
              format-ethernet = "{ifname}: {ipaddr}/{cidr}   up: {bandwidthUpBits} down: {bandwidthDownBits}";
            };
            cpu = {
              format = "{usage}% ";
              tooltip = false;
            };
            clock = {
              format-alt = "{:%a, %d. %b  %H:%M}";
            };
          };
        };
        # style = ''
        #   * {
        #     border: none;
        #     border-radius: 0;
        #     font-family: Source Code Pro;
        #   }
        #   window#waybar {
        #     background: #16191C;
        #     color: #AAB2BF;
        #   }
        #   #workspaces button {
        #     padding: 0 5px;
        #   }
        #   .custom-spotify {
        #     padding: 0 10px;
        #     margin: 0 4px;
        #     background-color: #1DB954;
        #     color: black;
        #   }
        # '';
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
      ++ (if config.colinsane.gui.sway.enable then
      [
        # TODO: move this to helpers/gui/sway.nix?
        pkgs.swaylock
        pkgs.swayidle
        pkgs.wl-clipboard
        pkgs.mako # notification daemon
        # pkgs.dmenu # todo: use wofi?
        # user stuff
        # pkgs.pavucontrol
        pkgs.sway-contrib.grimshot
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
