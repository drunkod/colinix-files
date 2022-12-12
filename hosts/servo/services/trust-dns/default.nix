{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  systemd.services.ddns-trust-dns = {
    description = "update dynamic DNS entries for self-hosted trust-dns";
    after = [ "network.target" ];
    restartTriggers = [ ./uninsane.org.zone ];
    script = let
      sed = "${pkgs.gnused}/bin/sed";
      curl = "${pkgs.curl}/bin/curl -4";
      sha256sum = "${pkgs.coreutils-full}/bin/sha256sum";
      cut = "${pkgs.coreutils-full}/bin/cut";
      zone-state = "/var/lib/trust-dns/uninsane.org.zone";
      diff = "${pkgs.diffutils}/bin/diff";
      systemctl = "${pkgs.systemd}/bin/systemctl";
    in ''
      mkdir -p /var/lib/trust-dns
      ip=$(${curl} https://ipinfo.io/ip)

      # TODO: validate that this is really our IP!
      ${sed} s/%NATIVE%/$ip/ ${./uninsane.org.zone} > ${zone-state}.new

      # see if anything changed
      touch ${zone-state}
      old_sha=$(${sha256sum} ${zone-state} | ${cut} -f 1 -d' ' )
      new_sha=$(${sha256sum} ${zone-state}.new | ${cut} -f 1 -d' ' )
      cp ${zone-state} ${zone-state}.old
      mv ${zone-state}.new ${zone-state}
      # if so, restart trust-dns
      if [ "$new_sha" != "$old_sha" ]
      then
        echo "zone changed: restarting"
        ${diff} -u ${zone-state}.old ${zone-state} || true
        ${systemctl} restart trust-dns.service
      else
        echo "zone unchanged. ip: $ip"
      fi
    '';
  };

  systemd.timers.ddns-trust-dns = {
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
    after = [ "network.target" "ddns-trust-dns.service" ];
    wants = [ "ddns-trust-dns.timer" ];
    wantedBy = [ "multi-user.target" ];
  };
}
