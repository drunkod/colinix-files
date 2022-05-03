# docs: https://nixos.wiki/wiki/Nginx
{ config, pkgs, lib, ... }:

{
  services.nginx.enable = true;
  # services.nginx.config = pkgs.lib.readFile /etc/nixos/services/nginx.conf;
  # services.nginx.httpConfig = ''
  # server {
  #   server_name uninsane.org;
  #   listen 80;
  #   location / {
  #     root /home/nixos;
  #     index index.html;
  #   }
  #   
  #   location ~* \.(png|ico|gif|jpg|jpeg)$ {
  #     expires 60m;
  #   }

  #   location /share/ {
  #     autoindex on;
  #   }
  # }
  # '';
  services.nginx.virtualHosts."uninsane.org" = {
    root = "/mnt/storage/opt/uninsane/root";
    addSSL = true;
    enableACME = true;

    # allow matrix users to discover that user@uninsane.org is reachable via matrix.uninsane.org
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
  };

  services.nginx.virtualHosts."fed.uninsane.org" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4000";
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
        proxy_set_header Host $host;

	# colin: added this due to Pleroma complaining in its logs
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        client_max_body_size 16m;
      '';
    };
  };

  # transmission
  services.nginx.virtualHosts."bt.uninsane.org" = {
    # basicAuth is literally cleartext user/pw, so FORCE this to happen over SSL
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      # created with htpasswd -c bt.htpasswd <user>
      basicAuthFile = "/etc/nixos/services-conf/bt.htpasswd";
      proxyPass = "http://127.0.0.1:9091";
    };
  };

  services.nginx.virtualHosts."matrix.uninsane.org" = {
    addSSL = true;
    enableACME = true;

    # TODO colin: replace this with something helpful to the viewer
    # locations."/".extraConfig = ''
    #   return 404;
    # '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:8008";
    };

    # locations."/_matrix" = {
    #   proxyPass = "http://127.0.0.1:8008";
    # };
  };

  services.nginx.virtualHosts."git.uninsane.org" = {
    addSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
    };
  };

  # this is mostly taken from the official jellfin.org docs
  services.nginx.virtualHosts."jelly.uninsane.org" = {
    addSSL = true;
    enableACME = true;

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

  security.acme.acceptTerms = true;
  security.acme.email = "acme@uninsane.org";
}
