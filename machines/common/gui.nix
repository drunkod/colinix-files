{ config, pkgs, lib, ... }:

{
  # start gnome/gdm on boot
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  networking.useDHCP = false;
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;
}
