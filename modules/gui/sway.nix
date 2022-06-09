{ pkgs, lib, config, ... }:
 
# docs: https://nixos.wiki/wiki/Sway
with lib;
let
  cfg = config.colinsane.gui.sway;
in
{
  options = {
    colinsane.gui.sway.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };
  config = mkIf cfg.enable {
    colinsane.gui.enable = true;
    programs.sway = {
      # we configure sway with home-manager, but this enable gets us e.g. opengl and fonts
      enable = true;
    };

    # TODO: should be able to use SDDM to get interactive login
    services.greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.sway}/bin/sway";
          user = "colin";
        };
        default_session = initial_session;
      };
    };

    # unlike other DEs, sway configures no audio stack
    # administer with pw-cli, pw-mon, pw-top commands
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;  # ??
      pulse.enable = true;
    };

    networking.useDHCP = false;
    networking.networkmanager.enable = true;
    networking.wireless.enable = lib.mkForce false;

    colinsane.home-manager.windowManager.sway = {
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
  };
}

