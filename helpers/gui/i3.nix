{ pkgs, ... }:
{
  environment.pathsToLink = [ "/libexec" ];  # patch for i3blocks to work
  services.xserver.enable = true;
  services.xserver.displayManager.defaultSession = "none+i3";
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3status
      i3lock
      i3blocks
    ];
  };
}

