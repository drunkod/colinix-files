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

      services.xserver.windowManager.session = [{
        name = "sxmo";
        desktopNames = [ "sxmo" ];
        start = ''
          ${pkgs.sxmo-utils}/bin/sxmo_xinit.sh &
          waitPID=$!
        '';
      }];
    })
  ];
}
