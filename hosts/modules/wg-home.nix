{ config, lib, ... }:

let
  inherit (lib) optionalAttrs;
  me = config.sane.hosts.target;
in
{
  # wireguard VPN which allows everything on my domain to speak to each other even when
  # not behind a shared LAN.
  # this config defines both the endpoint (server) and client configs

  networking.firewall.allowedUDPPorts = [ 51820 ];
  # TODO: remove this hacky `if` block
  networking.wireguard.interfaces.wg-home = {
    privateKeyFile = config.sops.secrets.wg_home_privkey.path;
    listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)
  } // (optionalAttrs me.roles.client {
    # client IP (TODO: make host-specific)
    ips = [ "10.0.10.20/32" ];

    peers = [
      {
        # server pubkey
        publicKey = "pWtnKW7f7sNIZQ2M83uJ7cHg3IL1tebE3IoVkCgjkXM=";

        # accept traffic from any IP addr on the other side of the tunnel
        allowedIPs = [ "0.0.0.0/0" ];

        endpoint = "uninsane.org:51820";

        # send keepalives every 25 seconds to keep NAT routes live
        persistentKeepalive = 25;
      }
    ];
  }) // (optionalAttrs me.roles.server {
    ips = [
      "10.0.10.5/24"
    ];
    peers = [
      {
        # peers and host all use the same key
        publicKey = "pWtnKW7f7sNIZQ2M83uJ7cHg3IL1tebE3IoVkCgjkXM=";
        allowedIPs = [ "10.0.10.0/24" ];
        # allowedIPs = [ "10.0.10.0/24" "192.168.0.0/24" ];
        # allowedIPs = [ "0.0.0.0/0" ];
      }
      # {
      #   # lappy
      #   publicKey = "TODO";
      #   allowedIPs = [ "10.0.10.20/32" ];
      # }
      # {
      #   # desko
      #   publicKey = "TODO";
      #   allowedIPs = [ "10.0.10.22/32" ];
      # }
      # {
      #   # moby
      #   publicKey = "TODO";
      #   allowedIPs = [ "10.0.10.48/32" ];
      # }
    ];
  });
}
