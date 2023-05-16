# this work derives from noneucat's sxmo service/packages, found via NUR
# - <repo:nix-community/nur-combined:repos/noneucat/modules/pinephone/sxmo.nix>
{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.sane.gui.phosh;
in
{
  options = {
    sane.gui.sxmo.enable = mkOption {
      default = false;
      type = types.bool;
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

    (mkIf config.sane.gui.sxmo.enable {
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
        gojq
        inotify-tools
        libnotify
        superd
        sway
        sxmo-utils
        xdg-user-dirs
      ];
      environment.sessionVariables.XDG_DATA_DIRS = [
        # TODO: only need the share/sxmo directly linked
        "${pkgs.sxmo-utils}/share"
      ];
    })
  ];
}
