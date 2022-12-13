{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  systemd.services.ddns-trust-dns = {
    description = "update dynamic DNS entries for self-hosted trust-dns";
    after = [ "network.target" ];
    restartTriggers = [ ./uninsane.org.zone ];
    serviceConfig.Type = "oneshot";
    script = let
      sed = "${pkgs.gnused}/bin/sed";
      curl = "${pkgs.curl}/bin/curl -4";
      sha256sum = "${pkgs.coreutils-full}/bin/sha256sum";
      cut = "${pkgs.coreutils-full}/bin/cut";
      zone-state = "/var/lib/trust-dns/uninsane.org.zone";
      diff = "${pkgs.diffutils}/bin/diff";
      systemctl = "${pkgs.systemd}/bin/systemctl";
    in ''
      set -ex
      mkdir -p /var/lib/trust-dns
      ip=$(${curl} https://ipinfo.io/ip)

      # TODO: validate that this is really our IP!
      # - i can host a service in ovpns which replies to pings
      ${sed} s/%NATIVE%/$ip/ ${./uninsane.org.zone} > ${zone-state}.new

      # see if anything changed
      # TODO: instead of diffing, we could `dig` against the actual deployment.
      # - that could be more resilient to races.
      touch ${zone-state}
      old_sha=$(${sha256sum} ${zone-state} | ${cut} -f 1 -d' ' )
      new_sha=$(${sha256sum} ${zone-state}.new | ${cut} -f 1 -d' ' )
      cp ${zone-state} ${zone-state}.old
      mv ${zone-state}.new ${zone-state}
      # if so, restart trust-dns
      if [ "$new_sha" != "$old_sha" ]
      then
        echo "zone changed."
        ${diff} -u ${zone-state}.old ${zone-state} || true
        status=$(${systemctl} is-active trust-dns.service || true)
        echo $status
        if [ "$status" = "active" ]
        then
          echo "restarting trust-dns."
          ${systemctl} restart trust-dns.service
        fi
      else
        echo "zone unchanged. ip: $ip"
      fi
    '';
  };

  systemd.timers.ddns-trust-dns = {
    # wantedBy = [ "multi-user.target" ];
    # wantedBy = [ "trust-dns.service" ];
    timerConfig = {
      OnStartupSec =    "10min";
      OnUnitActiveSec = "10min";
    };
  };

  systemd.services.trust-dns = {
    description = "trust-dns DNS server";
    serviceConfig = {
      ExecStart = ''
        ${pkgs.trust-dns}/bin/named \
          --config ${./uninsane.org.toml} \
          --zonedir /var/lib/trust-dns
      '';
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";
      # TODO: hardening (like, don't run as root!)
    };
    wants = [ "ddns-trust-dns.service" "ddns-trust-dns.timer" ];
    # XXX: can't be after ddns-trust-dns.service, because the latter `restarts` this one -- *before* it's done activating.
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
