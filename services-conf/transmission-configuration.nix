{ config, pkgs, lib, ... }:

{
  services.transmission.enable = true;
  services.transmission.settings = {
    rpc-bind-address = "0.0.0.0";
    #rpc-host-whitelist = "bt.uninsane.org";
    #rpc-whitelist = "*.*.*.*";
    rpc-authentication-required = true;
    rpc-username = "colin";
    # salted pw. to regenerate, set this plaintext, run nixos-rebuild, and then find the salted pw in:
    # /var/lib/transmission/.config/transmission-daemon/settings.json
    rpc-password = "{503fc8928344f495efb8e1f955111ca5c862ce0656SzQnQ5";
    rpc-whitelist-enabled = false;

    download-dir = "/mnt/storage/opt/uninsane/media/";
  };

  systemd.services.transmission.after = ["wireguard-wg0.service"];
  systemd.services.transmission.serviceConfig = {
    # run this behind the OVPN static VPN
    NetworkNamespacePath = "/run/netns/ovpns";
  };
}

