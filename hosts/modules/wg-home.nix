{ config, lib, pkgs, ... }:

let
  inherit (lib) mapAttrsToList mkIf mkMerge mkOption optionalAttrs types;
  cfg = config.sane.services.wg-home;
  server-cfg = config.sane.hosts.by-name."servo".wg-home;
in
{
  options = {
    sane.services.wg-home.enable = mkOption {
      type = types.bool;
      default = false;
    };
    sane.services.wg-home.ip = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
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

      ips = [
        "${cfg.ip}/24"
      ];

      # include all peers -- except for ourself
      peers = mapAttrsToList
        (name: hostcfg:
          mkIf (hostcfg.wg-home.ip != null && hostcfg.wg-home.ip != cfg.ip) {
            publicKey = hostcfg.wg-home.pubkey;
            allowedIPs = [ "${hostcfg.wg-home.ip}/32" ];
            endpoint = lib.mkIf
              (hostcfg.wg-home.endpoint != null)
              hostcfg.wg-home.endpoint;

            # send keepalives every 25 seconds to keep NAT routes live.
            # only need to do this from client -> server though, i think.
            persistentKeepalive = lib.mkIf
              (hostcfg.wg-home.endpoint != null)
              25;
          }
        )
        config.sane.hosts.by-name;
    };
  };
}
