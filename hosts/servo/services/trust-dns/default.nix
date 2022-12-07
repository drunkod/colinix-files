{ pkgs, ... }:

{
  systemd.services.trust-dns = {
    description = "trust-dns DNS server";
    serviceConfig = {
      ExecStart = ''
        ${pkgs.trust-dns}/bin/named \
          --config ${./uninsane.org.toml} \
          --zonedir ${./.}
      '';
      Type = "simple";
      Restart = "on-failure";
      # TODO: hardening
    };
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
