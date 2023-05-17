# this work derives from noneucat's sxmo service/packages, found via NUR
# - <repo:nix-community/nur-combined:repos/noneucat/modules/pinephone/sxmo.nix>
# other nix works:
# - <https://github.com/wentam/sxmo-nix>
# - <https://github.com/chuangzhu/nixpkgs-sxmo>
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
{ lib, config, pkgs, ... }:

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
    sane.gui.sxmo.deviceHooks = mkOption {
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
      type = types.nullOr (types.enum [ "foot" "st" "vte" ]);
      default = "st";
      description = ''
        name of terminal to use for sxmo_terminal.sh
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

      environment.systemPackages = with pkgs; [
        bemenu
        gojq
        inotify-tools
        libnotify
        lisgd
        mako
        superd
        sway
        sxmo-utils
        cfg.deviceHooks
        cfg.hooks
        xdg-user-dirs
      ] ++ lib.optionals (cfg.terminal != null) [ pkgs."${cfg.terminal}" ];
      environment.sessionVariables = {
        XDG_DATA_DIRS = [
          # TODO: only need the share/sxmo directly linked
          "${pkgs.sxmo-utils}/share"
        ];
        # XXX: make sure the user is part of the `input` group!
        SXMO_LISGD_INPUT_DEVICE = "/dev/input/by-id/usb-Wacom_Co._Ltd._Pen_and_multitouch_sensor-event-if00";
        # sxmo tries to determine device type from /proc/device-tree/compatible,
        # but that doesn't seem to exist on NixOS?  (or maybe it just doesn't exist
        # on non-aarch64 builds).
        # the device type informs (at least):
        # - SXMO_WIFI_MODULE
        # - SXMO_RTW_SCAN_INTERVAL
        # - SXMO_SYS_FILES
        # - SXMO_TOUCHSCREEN_ID
        # - SXMO_MONITOR
        # - SXMO_ALSA_CONTROL_NAME
        # - SXMO_SWAY_SCALE
        # see <repo:mil/sxmo-utils:scripts/deviceprofiles>
        # SXMO_DEVICE_NAME = "pine64,pinephone-1.2";
      } // lib.optionalAttrs (cfg.terminal != null) {
        TERMCMD = lib.mkDefault (if cfg.terminal == "vte" then "vte-2.91" else cfg.terminal);
      };
    })
  ];
}
