{ lib, config, ... }:

with lib;
let
  cfg = config.sane.gui.gnome;
in
{
  options = {
    sane.gui.gnome.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    sane.gui.enable = true;

    users.users.avahi.uid = config.sane.allocations.avahi-uid;
    users.groups.avahi.gid = config.sane.allocations.avahi-gid;
    users.users.colord.uid = config.sane.allocations.colord-uid;
    users.groups.colord.gid = config.sane.allocations.colord-gid;
    users.users.geoclue.uid = config.sane.allocations.geoclue-uid;
    users.groups.geoclue.gid = config.sane.allocations.geoclue-gid;
    users.users.rtkit.uid = config.sane.allocations.rtkit-uid;
    users.groups.rtkit.gid = config.sane.allocations.rtkit-gid;

    # start gnome/gdm on boot
    services.xserver.enable = true;
    services.xserver.desktopManager.gnome.enable = true;
    services.xserver.displayManager.gdm.enable = true;

    # gnome does networking stuff with networkmanager
    networking.useDHCP = false;
    networking.networkmanager.enable = true;
    networking.wireless.enable = lib.mkForce false;
  };
  # home-mananger.users.colin extras
  # obtain these by running `dconf dump /` after manually customizing gnome
  # TODO: fix "is not of type `GVariant value'"
  # dconf.settings = lib.mkIf (gui == "gnome") {
  #   gnome = {
  #     # control alt-tab behavior
  #     "org/gnome/desktop/wm/keybindings" = {
  #       switch-applications = [ "<Super>Tab" ];
  #       switch-applications-backward=[];
  #       switch-windows=["<Alt>Tab"];
  #       switch-windows-backward=["<Super><Alt>Tab"];
  #     };
  #     # idle power savings
  #     "org/gnome/settings-deamon/plugins/power" = {
  #       idle-brigthness = 50;
  #       sleep-inactive-ac-type = "nothing";
  #       sleep-inactive-battery-timeout = 5400;  # seconds
  #     };
  #     "org/gnome/shell" = {
  #       favorite-apps = [
  #         "org.gnome.Nautilus.desktop"
  #         "firefox.desktop"
  #         "kitty.desktop"
  #         # "org.gnome.Terminal.desktop"
  #       ];
  #     };
  #     "org/gnome/desktop/session" = {
  #       # how long until considering a session idle (triggers e.g. screen blanking)
  #       idle-delay = 900;
  #     };
  #     "org/gnome/desktop/interface" = {
  #       text-scaling-factor = 1.25;
  #     };
  #     "org/gnome/desktop/media-handling" = {
  #       # don't auto-mount inserted media
  #       automount = false;
  #       automount-open = false;
  #     };
  #   };
  # };

}
