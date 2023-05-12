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
    settings.federation.enabled = true;
    # federation.debug forces outbound federation queries to be run synchronously
    settings.federation.debug = true;
    settings.port = backendPort;
    # settings.database.host = "localhost";
    # defaults
    # settings.database = {
    #   user = "lemmy";
    #   host = "/run/postgresql";
    #   # host = "localhost";  # fails with "fe_sendauth: no password supplied"
    #   port = 5432;
    #   database = "lemmy";
    #   pool_size = 5;
    # };
    ui.port = uiPort;
    database.createLocally = true;
  };

  systemd.services.lemmy.serviceConfig = {
    # fix to use a normal user so we can configure perms correctly
    DynamicUser = mkForce false;
    User = "lemmy";
    Group = "lemmy";
    # Environment = [ "RUST_BACKTRACE=full" "RUST_LOG=info" ];
  };
  systemd.services.lemmy.environment = {
    RUST_BACKTRACE = "full";
    RUST_LOG = "debug";
    # upstream defaults LEMMY_DATABASE_URL = "postgres:///lemmy?host=/run/postgresql";
    # - Postgres complains that we didn't specify a user
    # lemmy formats the url as:
    # - postgres://{user}:{password}@{host}:{port}/{database}
    # SO suggests (https://stackoverflow.com/questions/3582552/what-is-the-format-for-the-postgresql-connection-string-url):
    # - postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]
    # LEMMY_DATABASE_URL = "postgres://lemmy@/run/postgresql";  # connection to server on socket "/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "run/postgresql" does not exist
    # LEMMY_DATABASE_URL = "postgres://lemmy?host=/run/postgresql";  # no PostgreSQL user name specified in startup packet
    # LEMMY_DATABASE_URL = mkForce "postgres://lemmy@?host=/run/postgresql";  # WORKS!
    LEMMY_DATABASE_URL = mkForce "postgres://lemmy@/lemmy?host=/run/postgresql";
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
      # see <LemmyNet/lemmy:docker/nginx.conf>
      # see <LemmyNet/lemmy-ansible:templates/nginx.conf>
      "/" = {
        # "frontend general requests"
        proxyPass = "$proxpass";
        extraConfig = ''
          set $proxpass "${ui}";
          if ($http_accept = "application/activity+json") {
            set $proxpass "${backend}";
          }
          if ($http_accept = "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\"") {
            set $proxpass "${backend}";
          }

          # XXX: lemmy-ansible nginx uses this maximally broad redirection
          # if ($http_accept ~ "^application/.*$") {
          #   set $proxpass "${backend}";
          # }
          # XXX: POST redirection occurs in lemmy-ansible and docker/nginx.conf but not docker/federation/nginx.conf
          if ($request_method = POST) {
            set $proxpass "${backend}";
          }

          # Cuts off the trailing slash on URLs to make them valid
          rewrite ^(.+)/+$ $1 permanent;

          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
      "~ ^/(api|pictrs|feeds|nodeinfo|.well-known)" = {
        # "backend"
        proxyPass = backend;
        # <lemmy-docs:src/en/administration/troubleshooting.md> calls out these lines for the websocket
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";

          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };

  sane.services.trust-dns.zones."uninsane.org".inet.CNAME."lemmy" = "native";
}
