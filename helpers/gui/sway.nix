{ pkgs, ... }:
 
# docs: https://nixos.wiki/wiki/Sway
{
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
}

