{ config, lib, ... }:
let
  inherit (builtins) toString;
  inherit (lib) mkForce;
  uiPort = 1234;  # default ui port is 1234
  backendPort = 8536; # default backend port is 8536
  # - i guess the "backend" port is used for federation?
in {
  services.lemmy = {
    enable = true;
    settings.hostname = "lemmy.uninsane.org";
    settings.options.federation.enabled = true;
    settings.options.port = backendPort;
    # settings.database.host = "localhost";
    ui.port = uiPort;
    database.createLocally = true;
  };

  systemd.services.lemmy.serviceConfig = {
    # fix to use a normal user so we can configure perms correctly
    DynamicUser = mkForce false;
    User = "lemmy";
    Group = "lemmy";
    Environment = [ "RUST_BACKTRACE=full" ];
  };
  users.groups.lemmy = {};
  users.users.lemmy = {
    group = "lemmy";
    isSystemUser = true;
  };

  services.nginx.virtualHosts."lemmy.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
    locations = let
      ui = "http://127.0.0.1:${toString uiPort}";
      backend = "http://127.0.0.1:${toString backendPort}";
    in {
      # see <LemmyNet/lemmy:docker/federation/nginx.conf>
      "~ ^/(api|pictrs|feeds|nodeinfo|.well-known)" = {
        extraConfig = ''
          set $proxpass ${ui};
          if ($http_accept = "application/activity+json") {
            set $proxpass ${backend};
          }
          if ($http_accept = "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\"") {
            set $proxpass ${backend};
          }

          # Cuts off the trailing slash on URLs to make them valid
          rewrite ^(.+)/+$ $1 permanent;
        '';
        proxyPass = "$proxpass";
      };
      "/".proxyPass = ui;
    };
  };

  sane.services.trust-dns.zones."uninsane.org".inet.CNAME."lemmy" = "native";
}