# docs:
# - <https://docs.ejabberd.im/admin/configuration/basic>
# example configs:
# - 2013: <https://github.com/processone/ejabberd/blob/master/ejabberd.yml.example>
{ lib, ... }:

# XXX disabled: fails to start because of `mnesia_tm` dependency
# lib.mkIf false
{
  sane.impermanence.service-dirs = [
    { user = "ejabberd"; group = "ejabberd"; directory = "/var/lib/ejabberd"; }
  ];
  networking.firewall.allowedTCPPorts = [
    5222  # XMPP client -> server
    5269  # XMPP server -> server
  ];

  # provide access to certs
  users.users.ejabberd.extraGroups = [ "nginx" ];

  # TODO: allocate UIDs/GIDs ?
  services.ejabberd.enable = true;
  services.ejabberd.configFile = builtins.toFile "ejabberd.yaml" ''
    hosts:
      - uninsane.org

    # none | emergency | alert | critical | error | warning | notice | info | debug
    loglevel: debug

    acme:
      auto: false
    certfiles:
      - /var/lib/acme/uninsane.org/fullchain.pem
      - /var/lib/acme/uninsane.org/key.pem

    pam_userinfotype: jid

    # docs: <https://docs.ejabberd.im/admin/configuration/basic/#shaper-rules>
    shaper_rules:
      max_s2s_connections: 3
      max_user_offline_messages: 5000
      c2s_shaper:
        fast: all
      s2s_shaper:
        med: all

    # docs: <https://docs.ejabberd.im/admin/configuration/basic/#shapers>
    # this limits the bytes/sec.
    # for example, burst: 3_000_000 and rate: 100_000 means:
    # - each client has a BW budget that accumulates 100kB/sec and is capped at 3 MB
    shaper:
      fast: 1000000
      med:   500000
    #   fast:
    #     - rate:        1000000
    #     - burst_size: 10000000
    #   med:
    #     - rate:         500000
    #     - burst_size:  5000000

    # see: <https://docs.ejabberd.im/admin/configuration/listen/>
    # TODO: host web admin panel
    s2s_use_starttls: true
    listen:
      -
        port: 5222
        module: ejabberd_c2s
        shaper: c2s_shaper
        starttls: true
      -
        port: 5269
        module: ejabberd_s2s_in
        shaper: s2s_shaper
      -
        port: 5280
        module: ejabberd_http
        request_handlers:
          /admin: ejabberd_web_admin
          /api: mod_http_api
          /bosh: mod_bosh
          /upload: mod_http_upload
          /ws: ejabberd_http_ws
  '';
}
