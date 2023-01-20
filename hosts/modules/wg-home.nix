{ config, lib, ... }:

let
  inherit (lib) mkIf mkMerge mkOption optionalAttrs types;
  cfg = config.sane.services.wg-home;
in
{
  options = {
    sane.services.wg-home.enable = mkOption {
      type = types.bool;
      default = false;
    };
    sane.services.wg-home.role = mkOption {
      type = types.enum [ "client" "server" ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # wireguard VPN which allows everything on my domain to speak to each other even when
      # not behind a shared LAN.
      # this config defines both the endpoint (server) and client configs

      # for convenience, have both the server and client use the same port for their wireguard connections.
      networking.firewall.allowedUDPPorts = [ 51820 ];
      networking.wireguard.interfaces.wg-home = {
        listenPort = 51820;
      };
    }

    {
      networking.wireguard.interfaces.wg-home = lib.mkIf (cfg.role == "client") {
        privateKeyFile = config.sops.secrets.wg_home_privkey.path;
        # client IP (TODO: make host-specific)
        ips = [ "10.0.10.20/24" ];

        peers = [
          {
            # server pubkey
            publicKey = "cy9tvnwGMqWhLxRZlvxDtHmknzqmedAaJz+g3Z0ILG0=";

            # accept traffic from any IP addr on the other side of the tunnel
            # allowedIPs = [ "0.0.0.0/0" ];
            allowedIPs = [ "10.0.10.5/32" ];

            # endpoint = "uninsane.org:51820";
            endpoint = "97.126.41.123:51820";

            # send keepalives every 25 seconds to keep NAT routes live
            persistentKeepalive = 25;
          }
        ];
      };
    }
    {
      networking.wireguard.interfaces.wg-home = lib.mkIf (cfg.role == "server") {
        privateKeyFile = config.sops.secrets.wg_home_server_privkey.path;
        ips = [
          "10.0.10.5/24"
        ];
        peers = [
          {
            # lappy
            publicKey = "pWtnKW7f7sNIZQ2M83uJ7cHg3IL1tebE3IoVkCgjkXM=";
            allowedIPs = [ "10.0.10.20/32" ];
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
      };
    }
  ]);
}
