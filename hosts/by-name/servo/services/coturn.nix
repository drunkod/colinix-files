# TURN/STUN NAT traversal service
# commonly used to establish realtime calls with prosody, or possibly matrix/synapse
{ lib, ... }:
let
  # TODO: this range could be larger, but right now that's costly because each element is its own UPnP forward
  # TURN port range (inclusive)
  turnPortLow = 49152;
  turnPortHigh = 49167;
  turnPortRange = lib.range turnPortLow turnPortHigh;
in
{
  sane.ports.ports = lib.mkMerge ([
    {
      "3478" = {
        # this is the "control" port.
        # i.e. no client data is forwarded through it, but it's where clients request tunnels.
        protocol = [ "tcp" "udp" ];
        visibleTo.lan = true;
        visibleTo.wan = true;
        description = "colin-stun-turn";
      };
      "5349" = {
        # the other port 3478 also supports TLS/DTLS, but presumably clients wanting TLS will default 5349
        protocol = [ "tcp" ];
        visibleTo.lan = true;
        visibleTo.wan = true;
        description = "colin-stun-turn-over-tls";
      };
    }
  ] ++ (builtins.map
    (port: {
      "${builtins.toString port}" = let
        count = port - turnPortLow + 1;
        numPorts = turnPortHigh - turnPortLow + 1;
      in {
        protocol = [ "tcp" "udp" ];
        visibleTo.lan = true;
        visibleTo.wan = true;
        description = "colin-turn-${builtins.toString count}-of-${builtins.toString numPorts}";
      };
    })
    turnPortRange
  ));

  services.nginx.virtualHosts."turn.uninsane.org" = {
    # allow ACME to procure a cert via nginx for this domain
    enableACME = true;
  };

  sane.derived-secrets."/var/lib/coturn/shared_secret.bin" = {
    encoding = "base64";
    # TODO: make this not globally readable
    acl.mode = "0644";
  };

  services.coturn.enable = true;
  services.coturn.realm = "turn.uninsane.org";
  services.coturn.cert = "/var/lib/acme/turn.uninsane.org/fullchain.pem";
  services.coturn.pkey = "/var/lib/acme/turn.uninsane.org/key.pem";
  services.coturn.static-auth-secret-file = "/var/lib/coturn/shared_secret.bin";
  services.coturn.min-port = turnPortLow;
  services.coturn.max-port = turnPortHigh;
  services.coturn.extraConfig = ''
    no-multicast-peers
  '';
}
