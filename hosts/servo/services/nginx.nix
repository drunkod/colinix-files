# docs: https://nixos.wiki/wiki/Nginx
{ config, pkgs, ... }:

let
  # make the logs for this host "public" so that they show up in e.g. metrics
  publog = vhost: vhost // {
    extraConfig = (vhost.extraConfig or "") + ''
      access_log /var/log/nginx/public.log vcombined;
    '';
  };

  kTLS = true;  # in-kernel TLS for better perf
in
{
  services.nginx.enable = true;
  services.nginx.appendConfig = ''
    # use 1 process per core.
    # may want to increase worker_connections too, but `ulimit -n` must be increased first.
    worker_processes auto;
  '';

  # this is the standard `combined` log format, with the addition of $host
  # so that we have the virtualHost in the log.
  # KEEP IN SYNC WITH GOACCESS
  # goaccess calls this VCOMBINED:
  # - <https://gist.github.com/jyap808/10570005>
  services.nginx.commonHttpConfig = ''
    log_format vcombined '$host:$server_port $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referrer" "$http_user_agent"';
    access_log /var/log/nginx/private.log vcombined;
  '';
  # sets gzip_comp_level = 5
  services.nginx.recommendedGzipSettings = true;
  # enables OCSP stapling (so clients don't need contact the OCSP server -- i do instead)
  # - doesn't seem to, actually: <https://www.ssllabs.com/ssltest/analyze.html?d=uninsane.org>
  # caches TLS sessions for 10m
  services.nginx.recommendedTlsSettings = true;
  # enables sendfile, tcp_nopush, tcp_nodelay, keepalive_timeout 65
  services.nginx.recommendedOptimisation = true;

  # web blog/personal site
  services.nginx.virtualHosts."uninsane.org" = publog {
    root = "${pkgs.uninsane-dot-org}/share/uninsane-dot-org";
    # a lot of places hardcode https://uninsane.org,
    # and then when we mix http + non-https, we get CORS violations
    # and things don't look right. so force SSL.
    forceSSL = true;
    enableACME = true;
    inherit kTLS;

    # uninsane.org/share/foo => /var/lib/uninsane/root/share/foo.
    # yes, nginx does not strip the prefix when evaluating against the root.
    locations."/share".root = "/var/lib/uninsane/root";

    # allow matrix users to discover that @user:uninsane.org is reachable via matrix.uninsane.org
    locations."= /.well-known/matrix/server".extraConfig =
      let
        # use 443 instead of the default 8448 port to unite
        # the client-server and server-server port for simplicity
        server = { "m.server" = "matrix.uninsane.org:443"; };
      in ''
        add_header Content-Type application/json;
        return 200 '${builtins.toJSON server}';
      '';
    locations."= /.well-known/matrix/client".extraConfig =
      let
        client = {
          "m.homeserver" =  { "base_url" = "https://matrix.uninsane.org"; };
          "m.identity_server" =  { "base_url" = "https://vector.im"; };
        };
      # ACAO required to allow element-web on any URL to request this json file
      in ''
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
        return 200 '${builtins.toJSON client}';
      '';

    # static URLs might not be aware of .well-known (e.g. registration confirmation URLs),
    # so hack around that.
    locations."/_matrix" = {
      proxyPass = "http://127.0.0.1:8008";
    };
    locations."/_synapse" = {
      proxyPass = "http://127.0.0.1:8008";
    };

    # allow ActivityPub clients to discover how to reach @user@uninsane.org
    # TODO: waiting on https://git.pleroma.social/pleroma/pleroma/-/merge_requests/3361/
    # locations."/.well-known/nodeinfo" = {
    #   proxyPass = "http://127.0.0.1:4000";
    #   extraConfig = pleromaExtraConfig;
    # };
  };

  # server statistics
  services.nginx.virtualHosts."sink.uninsane.org" = {
    addSSL = true;
    enableACME = true;
    inherit kTLS;
    root = "/var/lib/uninsane/sink";

    locations."/ws" = {
      proxyPass = "http://127.0.0.1:7890";
      # XXX not sure how much of this is necessary
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_buffering off;
        proxy_read_timeout 7d;
      '';
    };

  };

  # Pleroma server and web interface
  services.nginx.virtualHosts."fed.uninsane.org" = publog {
    forceSSL = true;  # pleroma redirects to https anyway
    enableACME = true;
    inherit kTLS;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4000";
      # documented: https://git.pleroma.social/pleroma/pleroma/-/blob/develop/installation/pleroma.nginx
      extraConfig = ''
        # XXX colin: this block is in the nixos examples: i don't understand all of it
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'POST, PUT, DELETE, GET, PATCH, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, Idempotency-Key' always;
        add_header 'Access-Control-Expose-Headers' 'Link, X-RateLimit-Reset, X-RateLimit-Limit, X-RateLimit-Remaining, X-Request-Id' always;
        if ($request_method = OPTIONS) {
            return 204;
        }

        add_header X-XSS-Protection "1; mode=block";
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header Referrer-Policy same-origin;
        add_header X-Download-Options noopen;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        # proxy_set_header Host $http_host;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # colin: added this due to Pleroma complaining in its logs
        # proxy_set_header X-Real-IP $remote_addr;
        # proxy_set_header X-Forwarded-Proto $scheme;

        client_max_body_size 16m;
      '';
    };
  };

  # transmission web client
  services.nginx.virtualHosts."bt.uninsane.org" = {
    # basicAuth is literally cleartext user/pw, so FORCE this to happen over SSL
    forceSSL = true;
    enableACME = true;
    inherit kTLS;
    locations."/" = {
      # proxyPass = "http://ovpns.uninsane.org:9091";
      proxyPass = "http://10.0.1.6:9091";
    };
  };

  # jackett torrent search
  services.nginx.virtualHosts."jackett.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
    inherit kTLS;
    locations."/" = {
      # proxyPass = "http://ovpns.uninsane.org:9117";
      proxyPass = "http://10.0.1.6:9117";
    };
  };

  # matrix chat server
  services.nginx.virtualHosts."matrix.uninsane.org" = publog {
    addSSL = true;
    enableACME = true;
    inherit kTLS;

    # TODO colin: replace this with something helpful to the viewer
    # locations."/".extraConfig = ''
    #   return 404;
    # '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:8008";
    };
    # redirect browsers to the web client.
    # i don't think native matrix clients ever fetch the root.
    # ideally this would be put behind some user-agent test though.
    locations."= /" = {
      return = "301 https://web.matrix.uninsane.org";
    };

    # locations."/_matrix" = {
    #   proxyPass = "http://127.0.0.1:8008";
    # };
  };

  # matrix web client
  # docs: https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-element-web
  services.nginx.virtualHosts."web.matrix.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
    inherit kTLS;

    root = pkgs.element-web.override {
      conf = {
        default_server_config."m.homeserver" = {
          "base_url" = "https://matrix.uninsane.org";
          "server_name" = "uninsane.org";
        };
      };
    };
  };

  # hosted git (web view and for `git <cmd>` use
  services.nginx.virtualHosts."git.uninsane.org" = publog {
    forceSSL = true;  # gitea complains if served over a different protocol than its config file says
    enableACME = true;
    inherit kTLS;

    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
    };
  };

  # Jellyfin multimedia server
  # this is mostly taken from the official jellfin.org docs
  services.nginx.virtualHosts."jelly.uninsane.org" = {
    addSSL = true;
    enableACME = true;
    inherit kTLS;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;

        # Disable buffering when the nginx proxy gets very resource heavy upon streaming
        proxy_buffering off;
      '';
    };
    # locations."/web/" = {
    #   proxyPass = "http://127.0.0.1:8096/web/index.html";
    #   extraConfig = ''
    #     proxy_set_header Host $host;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #     proxy_set_header X-Forwarded-Proto $scheme;
    #     proxy_set_header X-Forwarded-Protocol $scheme;
    #     proxy_set_header X-Forwarded-Host $http_host;
    #   '';
    # };
    locations."/socket" = {
      proxyPass = "http://127.0.0.1:8096";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
      '';
    };
  };

  services.nginx.virtualHosts."music.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
    inherit kTLS;
    locations."/".proxyPass = "http://127.0.0.1:4533";
  };

  services.nginx.virtualHosts."rss.uninsane.org" = {
    addSSL = true;
    enableACME = true;
    inherit kTLS;
    # the routing is handled by freshrss.nix
  };

  services.nginx.virtualHosts."ipfs.uninsane.org" = {
    # don't default to ssl upgrades, since this may be dnslink'd from a different domain.
    # ideally we'd disable ssl entirely, but some places assume it?
    addSSL = true;
    enableACME = true;
    inherit kTLS;

    default = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Ipfs-Gateway-Prefix "";
      '';
    };
  };

  # exists only to manage certs for dovecot
  services.nginx.virtualHosts."imap.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
  };
  # exists only to manage certs for Postfix
  services.nginx.virtualHosts."mx.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
  };
  services.nginx.virtualHosts."nixcache.uninsane.org" = {
    addSSL = true;
    enableACME = true;
    inherit kTLS;
    # serverAliases = [ "nixcache" ];
    locations."/".extraConfig = ''
      proxy_pass http://localhost:${toString config.services.nix-serve.port};
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    '';
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "admin.acme@uninsane.org";

  users.users.acme.uid = config.sane.allocations.acme-uid;
  users.groups.acme.gid = config.sane.allocations.acme-gid;
  sane.impermanence.service-dirs = [
    # TODO: mode?
    { user = "acme"; group = "acme"; directory = "/var/lib/acme"; }
  ];
}
