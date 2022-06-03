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

  # sound (ALSA): https://nixos.wiki/wiki/ALSA
  # test with `alsamixer`, `aplay -t raw /dev/urandom`
  # sound = {
  #   enable = true;
  #   mediaKeys.enable = true;
  # };
  # hardware.pulseaudio.enable = true;
  # hardware.pulseaudio.support32Bit = true;    ## If compatibility with 32-bit applications is desired.

  # # disable PC-speaker
  # boot.blacklistedKernelModules = [ "snd_pcsp" ];
  # # enable the right driver (`cat /proc/asound/modules`)
  # boot.extraModprobeConfig = ''
  #   options snd slots=snd-hda-intel
  #   options snd_hda_intel enable=0,1
  # '';

  # administer with pw-cli, pw-mon, pw-top commands
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # ??
    pulse.enable = true;
  };
}

