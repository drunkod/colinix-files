{ config, lib, pkgs, sane-lib, ... }:
 
# docs: https://nixos.wiki/wiki/Sway
with lib;
let
  cfg = config.sane.gui.sway;
  waybar-config = import ./waybar-config.nix pkgs;
  # waybar-config-text = lib.generators.toJSON {} waybar-config;
  waybar-config-text = (pkgs.formats.json {}).generate "waybar-config.json" waybar-config;

  # bare sway launcher
  sway-launcher = pkgs.writeShellScriptBin "sway-launcher" ''
    ${pkgs.sway}/bin/sway --debug > /tmp/sway.log 2>&1
  '';
  # start sway and have it construct the gtkgreeter
  sway-as-greeter = pkgs.writeShellScriptBin "sway-as-greeter" ''
    ${pkgs.sway}/bin/sway --debug --config ${sway-config-into-gtkgreet} > /tmp/sway-as-greeter.log 2>&1
  '';
  # (config file for the above)
  sway-config-into-gtkgreet = pkgs.writeText "greetd-sway-config" ''
    exec "${gtkgreet-launcher}"
  '';
  # gtkgreet which launches a layered sway instance
  gtkgreet-launcher = pkgs.writeShellScript "gtkgreet-launcher" ''
    # NB: the "command" field here is run in the user's shell.
    # so that command must exist on the specific user's path who is logging in. it doesn't need to exist system-wide.
    ${pkgs.greetd.gtkgreet}/bin/gtkgreet --layer-shell --command sway-launcher
  '';
  greeter-session = {
    # greeter session config
    command = "${sway-as-greeter}/bin/sway-as-greeter";
    # alternatives:
    # - TTY: `command = "${pkgs.greetd.greetd}/bin/agreety --cmd ${pkgs.sway}/bin/sway";`
    # - autologin: `command = "${pkgs.sway}/bin/sway"; user = "colin";`
    # - Dumb Login (doesn't work)": `command = "${pkgs.greetd.dlm}/bin/dlm";`
  };
  greeterless-session = {
    # no greeter
    command = "${sway-launcher}/bin/sway-launcher";
    user = "colin";
  };
in
{
  options = {
    sane.gui.sway.enable = mkOption {
      default = false;
      type = types.bool;
    };
    sane.gui.sway.useGreeter = mkOption {
      description = ''
        launch sway via a greeter (like greetd's gtkgreet).
        sway is usable without a greeter, but skipping the greeter means no PAM session.
      '';
      default = true;
      type = types.bool;
    };
  };
  config = mkMerge [
    {
      sane.programs.swayApps = {
        package = null;
        suggestedPrograms = [
          "guiApps"
          "splatmoji"  # used by us, but 'enabling' it gets us persistence & cfg
          "swaylock"
          "swayidle"
          "wl-clipboard"
          "blueberry"  # GUI bluetooth manager
          "mako"  # notification daemon
          # # "pavucontrol"
          # "gnome.gnome-bluetooth"  # XXX(2023/05/14): broken
          "gnome.gnome-control-center"
          "sway-contrib.grimshot"
        ];
      };
    }
    {
      sane.programs = {
        inherit (pkgs // {
          "gnome.gnome-bluetooth" = pkgs.gnome.gnome-bluetooth;
          "gnome.gnome-control-center" = pkgs.gnome.gnome-control-center;
          "sway-contrib.grimshot" = pkgs.sway-contrib.grimshot;
        })
          swaylock
          swayidle
          wl-clipboard
          blueberry
          mako
          "gnome.gnome-bluetooth"
          "gnome.gnome-control-center"
          "sway-contrib.grimshot"
        ;
      };
    }

    (mkIf cfg.enable {
      sane.programs.swayApps.enableFor.user.colin = true;

      # swap in these lines to use SDDM instead of `services.greetd`.
      # services.xserver.displayManager.sddm.enable = true;
      # services.xserver.enable = true;
      services.greetd = {
        # greetd source/docs:
        # - <https://git.sr.ht/~kennylevinsen/greetd>
        enable = true;
        settings = {
          default_session = if cfg.useGreeter then greeter-session else greeterless-session;
        };
      };
      # we need the greeter's command to be on our PATH
      users.users.colin.packages = [ sway-launcher ];

      # some programs (e.g. fractal) **require** a "Secret Service Provider"
      services.gnome.gnome-keyring.enable = true;

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

      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
      # gsd provides Rfkill, which is required for the bluetooth pane in gnome-control-center to work
      services.gnome.gnome-settings-daemon.enable = true;
      # start the components of gsd we need at login
      systemd.user.targets."org.gnome.SettingsDaemon.Rfkill".wantedBy = [ "graphical-session.target" ];
      # go ahead and `systemctl --user cat gnome-session-initialized.target`. i dare you.
      # the only way i can figure out how to get Rfkill to actually load is to just disable all the shit it depends on.
      # it doesn't actually seem to need ANY of them in the first place T_T
      systemd.user.targets."gnome-session-initialized".enable = false;
      # bluez can't connect to audio devices unless pipewire is running.
      # a system service can't depend on a user service, so just launch it at graphical-session
      systemd.user.services."pipewire".wantedBy = [ "graphical-session.target" ];

      programs.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
      };
      sane.user.fs.".config/sway/config" = sane-lib.fs.wantedText (import ./sway-config.nix {
        inherit config pkgs;
      });

      sane.user.fs.".config/waybar/config" = sane-lib.fs.wantedSymlinkTo waybar-config-text;

      # style docs: https://github.com/Alexays/Waybar/wiki/Styling
      sane.user.fs.".config/waybar/style.css" = sane-lib.fs.wantedText (builtins.readFile ./waybar-style.css);
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
    })
  ];
}

