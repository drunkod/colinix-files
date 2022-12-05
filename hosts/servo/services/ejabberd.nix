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
    5443  # web services (file uploads, websockets, admin)
  ];

  # provide access to certs
  users.users.ejabberd.extraGroups = [ "nginx" ];

  security.acme.certs."uninsane.org".extraDomainNames = [
    "pubsub.xmpp.uninsane.org"
    "upload.xmpp.uninsane.org"
    "vjid.xmpp.uninsane.org"
  ];

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

    acl:
      local:
        user_regexp: ""

    access_rules:
      local:
        - allow: local

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
        port: 5443
        module: ejabberd_http
        tls: true
        request_handlers:
          /admin: ejabberd_web_admin
          /api: mod_http_api
          /bosh: mod_bosh
          /upload: mod_http_upload
          /ws: ejabberd_http_ws

    # TODO: enable mod_client_state for net optimization
    # TODO: enable mod_conversejs for web-hosted XMPP client
    # TODO: enable mod_fail2ban
    # TODO: enable mod_host_meta
    # TODO(low): look into mod_http_fileserver for serving macros?
    # TODO: enable mod_muc ?
    # TODO: enable mod_offline for buffering messages to offline users/servers?
    modules:
      # allows users to set avatars in vCard
      # - <https://docs.ejabberd.im/admin/configuration/modules/#mod-avatar>
      # mod_avatar: {}
      mod_caps: {}  # for mod_pubsub
      # allows clients like Dino to discover where to upload files
      mod_disco:
        server_info:
          -
            modules: all
            name: abuse-addresses
            urls:
              - "mailto:admin.xmpp@uninsane.org"
              - "xmpp:colin@uninsane.org"
          -
            modules: all
            name: admin-addresses
            urls:
              - "mailto:admin.xmpp@uninsane.org"
              - "xmpp:colin@uninsane.org"
      mod_http_upload:
        host: upload.xmpp.uninsane.org
        hosts:
          - upload.xmpp.uninsane.org
        put_url: "https://@HOST@:5443/upload"
        dir_mode: "0750"
        file_mode: "0750"
        rm_on_unregister: false
      mod_ping: {}
      # docs: <https://docs.ejabberd.im/admin/configuration/modules/#mod-vcard>
      mod_vcard:
        allow_return_all: true  # all users are discoverable (?)
        host: vjid.xmpp.uninsane.org
        hosts:
          - vjid.xmpp.uninsane.org
        search: true
      mod_vcard_xupdate: {}  # needed for avatars
      # # docs: <https://docs.ejabberd.im/admin/configuration/modules/#mod-pubsub>
      # mod_pubsub:  # needed for avatars
      #   host: pubsub.xmpp.uninsane.org
      #   hosts:
      #     - pubsub.xmpp.uninsane.org
      #   plugins:
      #     - flat
      #     - pep
      mod_version: {}
  '';
}
