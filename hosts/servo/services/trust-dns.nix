{ config, pkgs, ... }:

{
  sane.services.trust-dns.enable = true;

  sane.services.trust-dns.listenAddrsIPv4 = [
    # specify each address explicitly, instead of using "*".
    # this ensures responses are sent from the address at which the request was received.
    "192.168.0.5"
    "10.0.1.5"
  ];

  sane.services.trust-dns.zones."uninsane.org".TTL = 900;
  sane.services.trust-dns.zones."uninsane.org".SOA = ''
    ; SOA record structure: <https://en.wikipedia.org/wiki/SOA_record#Structure>
    ; SOA MNAME RNAME (... rest)
    ; MNAME = Master name server for this zone. this is where update requests should be sent.
    ; RNAME = admin contact (encoded email address)
    ; Serial = YYYYMMDDNN, where N is incremented every time this file changes, to trigger secondary NS to re-fetch it.
    ; Refresh = how frequently secondary NS should query master
    ; Retry = how long secondary NS should wait until re-querying master after a failure (must be < Refresh)
    ; Expire = how long secondary NS should continue to reply to queries after master fails (> Refresh + Retry)
    @   IN          SOA     ns1.uninsane.org. admin-dns.uninsane.org. (
                                    2022121601 ; Serial
                                    4h         ; Refresh
                                    30m        ; Retry
                                    7d         ; Expire
                                    5m)        ; Negative response TTL
  '';

  sane.services.trust-dns.zones."uninsane.org".records = ''
    rev             TXT     "2022121601"

    ; @               A       %NATIVE%
    ; XXX NS records must also not be CNAME
    ; it's best that we keep this identical, or a superset of, what org. lists as our NS.
    ; so, org. can specify ns2/ns3 as being to the VPN, with no mention of ns1. we provide ns1 here.
    ; ns1             A       %NATIVE%
    ns2             A       185.157.162.178
    ns3             A       185.157.162.178
    ; native          A       %NATIVE%
    ovpns           A       185.157.162.178

    @               NS      ns1.uninsane.org.
    @               NS      ns2.uninsane.org.
    @               NS      ns3.uninsane.org.
    ;@               NS      uninsane.port0.org.
    ;@               NS      uninsane.psybnc.org.

    $INCLUDE /var/lib/trust-dns/native.uninsane.org.zone
  '';

  systemd.services.ddns-trust-dns = {
    description = "update dynamic DNS entries for self-hosted trust-dns";
    after = [ "network.target" ];
    wantedBy = [ "trust-dns.service" ];
    restartTriggers = [(
      builtins.toJSON config.sane.services.trust-dns
    )];
    serviceConfig.Type = "oneshot";
    script = let
      sed = "${pkgs.gnused}/bin/sed";
      curl = "${pkgs.curl}/bin/curl -4";
      zone-dir = "/var/lib/trust-dns";
      zone-out = "${zone-dir}/native.uninsane.org.zone";
      diff = "${pkgs.diffutils}/bin/diff";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      zone-template = pkgs.writeText "native.uninsane.org.zone.in" ''
        @               A       %NATIVE%
        ns1             A       %NATIVE%
        native          A       %NATIVE%
      '';
    in ''
      set -ex
      mkdir -p ${zone-dir}
      ip=$(${curl} https://ipinfo.io/ip)

      # TODO: validate that this is really our IP!
      # - i could host a service in ovpns which replies to pings
      ${sed} s/%NATIVE%/$ip/ ${zone-template} > ${zone-out}.new

      # see if anything changed
      # TODO: instead of diffing, we could `dig` against the actual deployment.
      # - that could be more resilient to races.
      touch ${zone-out}  # in case it didn't exist yet
      cp ${zone-out} ${zone-out}.old
      mv ${zone-out}.new ${zone-out}
      # if so, restart trust-dns
      if [ ${diff} -u ${zone-out}.old ${zone-out} ]
      then
        echo "zone unchanged. ip: $ip"
      else
        echo "zone changed."
        status=$(${systemctl} is-active trust-dns.service || true)
        echo $status
        if [ "$status" = "active" ]
        then
          echo "restarting trust-dns."
          ${systemctl} restart trust-dns.service
        fi
      fi
    '';
  };

  systemd.timers.ddns-trust-dns = {
    # wantedBy = [ "multi-user.target" ];
    wantedBy = [ "trust-dns.service" ];
    timerConfig = {
      OnStartupSec =    "10min";
      OnUnitActiveSec = "10min";
    };
  };
}
