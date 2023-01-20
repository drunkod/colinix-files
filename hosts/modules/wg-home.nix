{ config, lib, pkgs, ... }:

let
  inherit (builtins) mapAttrsToList;
  inherit (lib) mkIf mkMerge mkOption optionalAttrs types;
  cfg = config.sane.services.wg-home;
  server-cfg = config.sane.hosts.by-name."servo".wg-home;
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
      # generate a (deterministic) wireguard private key
      sane.derived-secrets."/run/wg-home.priv" = {
        len = 32;
        encoding = "base64";
      };

      # wireguard VPN which allows everything on my domain to speak to each other even when
      # not behind a shared LAN.
      # this config defines both the endpoint (server) and client configs

      # for convenience, have both the server and client use the same port for their wireguard connections.
      networking.firewall.allowedUDPPorts = [ 51820 ];
      networking.wireguard.interfaces.wg-home = {
        listenPort = 51820;
        privateKeyFile = "/run/wg-home.priv";
        preSetup =
          let
            gen-key = config.sane.fs."/run/wg-home.priv".unit;
          in
            "${pkgs.systemd}/bin/systemctl start '${gen-key}'";
      };
    }

    {
      networking.wireguard.interfaces.wg-home = lib.mkIf (cfg.role == "client") {
        # client IP (TODO: make host-specific)
        ips = [ "10.0.10.20/24" ];

        peers = [
          {
            # server pubkey
            publicKey = server-cfg.pubkey;

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
        ips = [
          "10.0.10.5/24"
        ];
        peers = mapAttrsToList
          (name: hostcfg:
            lib.mkIf (hostcfg.wg-home.ip or server-cfg.ip != server-cfg.ip) {
              publicKey = hostcfg.wg-home.pubkey;
              allowedIPs = [ "${hostcfg.wg-home.ip}/32" ];
            }
          )
          config.sane.hosts.by-name;
      };
    }
  ]);
}
