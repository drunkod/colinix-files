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
                                    2022121207 ; Serial
                                    4h         ; Refresh
                                    30m        ; Retry
                                    7d         ; Expire
                                    5m)        ; Negative response TTL
  '';
  # TODO: split into services
  sane.services.trust-dns.zones."uninsane.org".records = ''
    rev             TXT     "2022121402"

    ; @               A       %NATIVE%
    ; XXX: RFC's specify that the MX record CANNOT BE A CNAME
    mx              A       185.157.162.178
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

    @               MX      10 mx.uninsane.org.

    bt              CNAME   native
    fed             CNAME   native
    git             CNAME   native
    imap            CNAME   native
    ipfs            CNAME   native
    jackett         CNAME   native
    jelly           CNAME   native
    matrix          CNAME   native
    web.matrix      CNAME   native
    music           CNAME   native
    nixcache        CNAME   native
    pl-dev          CNAME   native
    rss             CNAME   native
    sink            CNAME   native
    w               CNAME   native

    xmpp            CNAME   native
    conference.xmpp CNAME   native
    pubsub.xmpp     CNAME   native
    upload.xmpp     CNAME   native
    vjid.xmpp       CNAME   native

    ; _Service._Proto.Name TTL Class SRV Priority Weight Port Target
    _xmpp-client._tcp                SRV 0        0      5222 native
    _xmpp-server._tcp                SRV 0        0      5269 native

    ; Sender Policy Framework:
    ;   +mx     => mail passes if it originated from the MX
    ;   +a      => mail passes if it originated from the A address of this domain
    ;   +ip4:.. => mail passes if it originated from this IP
    ;   -all    => mail fails if none of these conditions were met
    @               TXT "v=spf1 a mx -all"

    ; DKIM public key:
    mx._domainkey   TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCkSyMufc2KrRx3j17e/LyB+3eYSBRuEFT8PUka8EDX04QzCwDPdkwgnj3GNDvnB5Ktb05Cf2SJ/S1OLqNsINxJRWtkVfZd/C339KNh9wrukMKRKNELL9HLUw0bczOI4gKKFqyrRE9qm+4csCMAR79Te9FCjGV/jVnrkLdPT0GtFwIDAQAB"

    ; DMARC fields <https://datatracker.ietf.org/doc/html/rfc7489>:
    ;   p=none|quarantine|reject: what to do with failures
    ;   sp = p but for subdomains
    ;   rua = where to send aggregrate reports
    ;   ruf = where to send individual failure reports
    ;   fo=0|1|d|s  controls WHEN to send failure reports
    ;     (1=on bad alignment; d=on DKIM failure; s=on SPF failure);
    ; Additionally:
    ;   adkim=r|s  (is DKIM relaxed [default] or strict)
    ;   aspf=r|s   (is SPF relaxed [default] or strict)
    ;   pct = sampling ratio for punishing failures (default 100 for 100%)
    ;   rf = report format
    ;   ri = report interval
    _dmarc          TXT "v=DMARC1;p=quarantine;sp=reject;rua=mailto:admin+mail@uninsane.org;ruf=mailto:admin+mail@uninsane.org;fo=1:d:s"
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
