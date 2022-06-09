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
  };
}

