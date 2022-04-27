{ config, pkgs, ... }:

{
  networking.domain = "uninsane.org";

  # networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 25 80 443 ];
  # DLNA ports: https://jellyfin.org/docs/general/networking/index.html
  networking.firewall.allowedUDPPorts = [ 1900 7359 ];
}
