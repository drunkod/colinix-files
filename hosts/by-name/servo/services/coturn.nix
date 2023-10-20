# TURN/STUN NAT traversal service
# commonly used to establish realtime calls with prosody, or possibly matrix/synapse
#
# - <https://github.com/coturn/coturn/>
# - `man turnserver`
# - config docs: <https://github.com/coturn/coturn/blob/master/examples/etc/turnserver.conf>
#
# TODO: fix tel -> xmpp:
# - "ERROR: check_stun_auth: Cannot find credentials of user <XXXMMMNNNN>"
#
# N.B. during operation it's NORMAL to see "error 401".
# during session creation:
# - client sends Allocate request
# - server replies error 401, providing a realm and nonce
# - client uses realm + nonce + shared secret to construct an auth key & call Allocate again
# - server replies Allocate Success Response
# - source: <https://stackoverflow.com/a/66643135>
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
        # visibleTo.lan = true;
        # visibleTo.wan = true;
        visibleTo.ovpn = true;
        description = "colin-stun-turn";
      };
      "5349" = {
        # the other port 3478 also supports TLS/DTLS, but presumably clients wanting TLS will default 5349
        protocol = [ "tcp" ];
        # visibleTo.lan = true;
        # visibleTo.wan = true;
        visibleTo.ovpn = true;
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
        # visibleTo.lan = true;
        # visibleTo.wan = true;
        visibleTo.ovpn = true;
        description = "colin-turn-${builtins.toString count}-of-${builtins.toString numPorts}";
      };
    })
    turnPortRange
  ));

  services.nginx.virtualHosts."turn.uninsane.org" = {
    # allow ACME to procure a cert via nginx for this domain
    enableACME = true;
  };
  sane.dns.zones."uninsane.org".inet = {
    # CNAME."turn" = "servo.wan";
    # CNAME."turn" = "ovpns";
    # CNAME."turn" = "native";
    # XXX: SRV records have to point to something with a A/AAAA record; no CNAMEs
    A."turn" = "%AOVPNS%";
    # A."turn" = "%AWAN%";

    SRV."_stun._udp" =                        "5 50 3478 turn";
    SRV."_stun._tcp" =                        "5 50 3478 turn";
    SRV."_stuns._tcp" =                       "5 50 5349 turn";
    SRV."_turn._udp" =                        "5 50 3478 turn";
    SRV."_turn._tcp" =                        "5 50 3478 turn";
    SRV."_turns._tcp" =                       "5 50 5349 turn";
  };

  sane.derived-secrets."/var/lib/coturn/shared_secret.bin" = {
    encoding = "base64";
    # TODO: make this not globally readable
    acl.mode = "0644";
  };
  sane.fs."/var/lib/coturn/shared_secret.bin".wantedBeforeBy = [ "coturn.service" ];

  # provide access to certs
  users.users.turnserver.extraGroups = [ "nginx" ];

  services.coturn.enable = true;
  services.coturn.realm = "turn.uninsane.org";
  services.coturn.cert = "/var/lib/acme/turn.uninsane.org/fullchain.pem";
  services.coturn.pkey = "/var/lib/acme/turn.uninsane.org/key.pem";
  services.coturn.use-auth-secret = true;
  services.coturn.static-auth-secret-file = "/var/lib/coturn/shared_secret.bin";
  services.coturn.lt-cred-mech = true;
  services.coturn.min-port = turnPortLow;
  services.coturn.max-port = turnPortHigh;
  # services.coturn.secure-stun = true;
  services.coturn.extraConfig = lib.concatStringsSep "\n" [
    "verbose"
    # "Verbose"  #< even MORE verbosity than "verbose"
    # "no-multicast-peers"  # disables sending to IPv4 broadcast addresses (e.g. 224.0.0.0/3)
    "listening-ip=10.0.1.5"
    # "external-ip=185.157.162.178/10.0.1.5"
    "external-ip=185.157.162.178"
    # "listening-ip=10.78.79.51"  # can be specified multiple times; omit for *
    # "external-ip=97.113.128.229/10.78.79.51"
    # "external-ip=97.113.128.229"
    # "mobility"  # "mobility with ICE (MICE) specs support" (?)
  ];
}
