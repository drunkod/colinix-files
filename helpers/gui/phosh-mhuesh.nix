# source: https://github.com/NixOS/mobile-nixos/blob/master/examples/phosh/configuration.nix
# source: https://github.com/mhuesch/pinephone-mobile-nixos-flake-example/blob/main/configuration-pinephone.nix
{ pkgs, ... }:

{
  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "colin";
    group = "users";
  };

  programs.calls.enable = true;
  hardware.sensor.iio.enable = true;

  environment.systemPackages = [
    pkgs.chatty
    pkgs.kgx
    pkgs.megapixels
  ];



  # # "desktop" environment configuration
  # powerManagement.enable = true;
  # hardware.opengl.enable = true;

  # systemd.defaultUnit = "graphical.target";

  # services.xserver.desktopManager.phosh = {
  #   enable = true;
  # #   user = "colin";
  #   group = "users";
  # };
  # # services.xserver.desktopManager.phosh.enable = true;
  # systemd.services.phosh = {
  #   wantedBy = [ "graphical.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.phosh}/bin/phosh";
  #     User = 1000;
  #     PAMName = "login";
  #     WorkingDirectory = "~";

  #     TTYPath = "/dev/tty7";
  #     TTYReset = "yes";
  #     TTYVHangup = "yes";
  #     TTYVTDisallocate = "yes";

  #     StandardInput = "tty-fail";
  #     StandardOutput = "journal";
  #     StandardError = "journal";

  #     UtmpIdentifier = "tty7";
  #     UtmpMode = "user";

  #     Restart = "always";
  #   };
  # };
  # services.xserver.desktopManager.gnome.enable = true;

  # # unpatched gnome-initial-setup is partially broken in small screens
  # services.gnome.gnome-initial-setup.enable = false;

  # #programs.phosh.enable = true;
}
