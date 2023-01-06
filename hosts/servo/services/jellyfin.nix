{ config, lib, ... }:

# TODO: re-enable after migrating media dir to /var/lib/uninsane/media
# else it's too spammy
lib.mkIf false
{
  networking.firewall.allowedUDPPorts = [
    1900 7359 # DLNA: https://jellyfin.org/docs/general/networking/index.html
  ];
  sane.persist.sys.plaintext = [
    # TODO: mode? could be more granular
    { user = "jellyfin"; group = "jellyfin"; directory = "/var/lib/jellyfin"; }
  ];

  # Jellyfin multimedia server
  # this is mostly taken from the official jellfin.org docs
  services.nginx.virtualHosts."jelly.uninsane.org" = {
    addSSL = true;
    enableACME = true;
    # inherit kTLS;

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

  sane.services.trust-dns.zones."uninsane.org".inet.CNAME."jelly" = "native";

  # users.users.jellyfin.uid = config.sane.allocations.jellyfin-uid;
  # users.groups.jellyfin.gid = config.sane.allocations.jellyfin-gid;
  services.jellyfin.enable = true;
}
