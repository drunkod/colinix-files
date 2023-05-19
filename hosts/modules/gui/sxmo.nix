# this work derives from noneucat's sxmo service/packages, found via NUR
# - <repo:nix-community/nur-combined:repos/noneucat/modules/pinephone/sxmo.nix>
# other nix works:
# - <https://github.com/wentam/sxmo-nix>
#   - implements sxmo atop tinydm (also packaged by wentam)
#   - wentam cleans up sxmo-utils to be sealed. also patches to use systemd poweroff, etc
#   - packages a handful of anjan and proycon utilities
#   - packages <https://gitlab.com/kop316/mmsd/>
#   - packages <https://gitlab.com/kop316/vvmd/>
# - <https://github.com/chuangzhu/nixpkgs-sxmo>
#   - implements sxmo as a direct systemd service -- apparently no DM
#   - packages sxmo-utils
#     - injects PATH into each script
# - perhaps sxmo-utils is best packaged via the `resholve` shell solver?
#
# sxmo documentation:
# - <repo:anjan/sxmo-docs-next>
#
# sxmo technical overview:
# - inputs
#   - dwm: handles vol/power buttons; hardcoded in config.h
#   - lisgd: handles gestures
# - startup
#   - daemon based (lisgsd, idle_locker, statusbar_periodics)
#   - auto-started at login
#   - managable by `sxmo_daemons.sh`
#     - list available daemons: `sxmo_daemons.sh list`
#     - query if a daemon is active: `sxmo_daemons.sh running <my-daemon>`
#     - start daemon: `sxmo_daemons.sh start <my-daemon>`
#   - managable by `superctl`
#     - `superctl status`
# - user hooks:
#   - live in ~/.config/sxmo/hooks/
# - logs:
#   - live in ~/.local/state/sxmo.log
#   - ~/.local/state/superd.log
#   - ~/.local/state/superd/logs/<daemon>.log
#   - `journalctl --user --boot`  (lightm redirects the sxmo session stdout => systemd)
#
# - default components:
#   - DE:                  sway (if wayland), dwm (if X)
#   - menus:               bemenu (if wayland), dmenu (if X)
#   - gestures:            lisgd
#   - on-screen keyboard:  wvkbd (if wayland), svkbd (if X)
#
{ lib, config, pkgs, sane-lib, ... }:

with lib;
let
  cfg = config.sane.gui.sxmo;
in
{
  options = {
    sane.gui.sxmo.enable = mkOption {
      default = false;
      type = types.bool;
    };
    sane.gui.sxmo.hooks = mkOption {
      type = types.package;
      default = pkgs.runCommand "sxmo-hooks" { } ''
        mkdir -p $out
        ln -s ${pkgs.sxmo-utils}/share/sxmo/default_hooks $out/bin
      '';
      description = ''
        hooks to make visible to sxmo.
        a hook is a script generally of the name sxmo_hook_<thing>.sh
        which is called by sxmo at key moments to proide user programmability.
      '';
    };
    sane.gui.sxmo.deviceHooks.package = mkOption {
      type = types.package;
      default = pkgs.runCommand "sxmo-device-hooks" { } ''
        mkdir -p $out
        ln -s ${pkgs.sxmo-utils}/share/sxmo/default_hooks/unknown $out/bin
      '';
      description = ''
        device-specific hooks to make visible to sxmo.
        this package supplies things like `sxmo_hook_inputhandler.sh`.
        a hook is a script generally of the name sxmo_hook_<thing>.sh
        which is called by sxmo at key moments to proide user programmability.
      '';
    };
    sane.gui.sxmo.terminal = mkOption {
      # type = types.nullOr (types.enum [ "foot" "st" "vte" ]);
      type = types.nullOr types.string;
      default = "foot";
      description = ''
        name of terminal to use for sxmo_terminal.sh.
        foot, st, and vte have special integrations in sxmo, but any will work.
      '';
    };
    sane.gui.sxmo.settings = mkOption {
      type = types.attrsOf types.string;
      default = {};
      description = ''
        environment variables used to configure sxmo.
        e.g. SXMO_UNLOCK_IDLE_TIME or SXMO_VOLUME_BUTTON.
      '';
    };
  };

  config = mkMerge [
    {
      sane.programs.sxmoApps = {
        package = null;
        suggestedPrograms = [
          "guiApps"
        ];
      };
    }

    (mkIf cfg.enable {
      sane.programs.sxmoApps.enableFor.user.colin = true;

      # TODO: probably need to enable pipewire

      networking.useDHCP = false;
      networking.networkmanager.enable = true;
      networking.wireless.enable = lib.mkForce false;

      hardware.bluetooth.enable = true;
      services.blueman.enable = true;

      # sxmo internally uses doas instead of sudo
      security.doas.enable = true;
      security.doas.wheelNeedsPassword = false;

      # services.xserver.windowManager.session = [{
      #   name = "sxmo";
      #   desktopNames = [ "sxmo" ];
      #   start = ''
      #     ${pkgs.sxmo-utils}/bin/sxmo_xinit.sh &
      #     waitPID=$!
      #   '';
      # }];
      # services.xserver.enable = true;

      # services.greetd = {
      #   enable = true;
      #   settings = {
      #     default_session = {
      #       command = "${pkgs.sxmo-utils}/bin/sxmo_winit.sh";
      #       user = "colin";
      #     };
      #   };
      # };

      services.xserver.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      services.xserver.displayManager.lightdm.greeters.gtk.enable = true;
      services.xserver.displayManager.lightdm.extraSeatDefaults = ''
        user-session = swmo
      '';
      services.xserver.displayManager.sessionPackages = [ pkgs.sxmo-utils ];

      # TODO: not all of these fonts seem to be mapped to the correct icon
      fonts.fonts = [ pkgs.nerdfonts ];

      # i believe sxmo recomments a different audio stack
      # administer with pw-cli, pw-mon, pw-top commands
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;  # ??
        pulse.enable = true;
      };
      systemd.user.services."pipewire".wantedBy = [ "graphical-session.target" ];

      environment.systemPackages = with pkgs; [
        bc
        bemenu
        bonsai
        conky
        gojq
        inotify-tools
        jq
        libnotify
        lisgd
        mako
        superd
        sway
        swayidle
        sxmo-utils
        wob
        xdg-user-dirs

        # X11 only?
        xdotool

        cfg.deviceHooks
        cfg.hooks
      ] ++ lib.optionals (cfg.terminal != null) [ pkgs."${cfg.terminal}" ];

      environment.sessionVariables = {
        XDG_DATA_DIRS = [
          # TODO: only need the share/sxmo directly linked
          "${pkgs.sxmo-utils}/share"
        ];
      } // lib.optionalAttrs (cfg.terminal != null) {
        TERMCMD = lib.mkDefault (if cfg.terminal == "vte" then "vte-2.91" else cfg.terminal);
      } // cfg.settings;

      sane.user.fs.".cache/sxmo/sxmo.noidle" = sane-lib.fs.wantedText "";
    })
  ];
}
