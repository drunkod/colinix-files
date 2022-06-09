# docs: https://nixos.wiki/wiki/Matrix
# docs: https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
{ config, ... }:

{
  services.matrix-synapse.enable = true;
  services.matrix-synapse.settings.server_name = "uninsane.org";

  # services.matrix-synapse.enable_registration_captcha = true;
  # services.matrix-synapse.enable_registration_without_verification = true;
  services.matrix-synapse.settings.enable_registration = true;
  # services.matrix-synapse.registration_shared_secret = "<shared key goes here>";

  # default for listeners is port = 8448, tls = true, x_forwarded = false.
  # we change this because the server is situated behind nginx.
  services.matrix-synapse.settings.listeners = [
    {
      port = 8008;
      bind_addresses = [ "127.0.0.1" ];
      type = "http";
      tls = false;
      x_forwarded = true;
      resources = [
        {
          names = [ "client" "federation" ];
          compress = false;
        }
      ];
    }
  ];

  services.matrix-synapse.settings.admin_contact = "admin.matrix@uninsane.org";
  services.matrix-synapse.settings.registrations_require_3pid = [ "email" ];

  services.matrix-synapse.extraConfigFiles = [
    config.sops.secrets.matrix_synapse_secrets.path
  ];

  # services.matrix-synapse.extraConfigFiles = [builtins.toFile "matrix-synapse-extra-config" ''
  #   admin_contact: "admin.matrix@uninsane.org"
  #   registrations_require_3pid:
  #     - email
  #   email:
  #     smtp_host: "mx.uninsane.org"
  #     smtp_port: 587
  #     smtp_user: "matrix-synapse"
  #     smtp_pass: "${secrets.matrix-synapse.smtp_pass}"
  #     require_transport_security: true
  #     enable_tls: true
  #     notif_from: "%(app)s <notify.matrix@uninsane.org>"
  #     app_name: "Uninsane Matrix"
  #     enable_notifs: true
  #     validation_token_lifetime: 96h
  #     invite_client_location: "https://web.matrix.uninsane.org"
  #     subjects:
  #       email_validation: "[%(server_name)s] Validate your email"
  # ''];
  services.matrix-synapse.settings.app_service_config_files = [
    "/var/lib/matrix-appservice-irc/registration.yml"  # auto-created by irc appservice
  ];

  # new users may be registered on the CLI:
  #   register_new_matrix_user -c /nix/store/8n6kcka37jhmi4qpd2r03aj71pkyh21s-homeserver.yaml http://localhost:8008
  #
  # or provide an registration token then can use to register through the client.
  #   docs: https://github.com/matrix-org/synapse/blob/develop/docs/usage/administration/admin_api/registration_tokens.md
  # first, grab your own user's access token (Help & About section in Element). then:
  #   curl --header "Authorization: Bearer <my_token>" localhost:8008/_synapse/admin/v1/registration_tokens
  # create a token with unlimited uses:
  #   curl -d '{}' --header "Authorization: Bearer <my_token>" localhost:8008/_synapse/admin/v1/registration_tokens/new
  # create a token with limited uses:
  #   curl -d '{ "uses_allowed": 1 }' --header "Authorization: Bearer <my_token>" localhost:8008/_synapse/admin/v1/registration_tokens/new

  # IRC bridging
  # note: Rizon allows only FOUR simultaneous IRC connections per IP: https://wiki.rizon.net/index.php?title=Connection/Session_Limit_Exemptions
  # Rizon supports CertFP for auth: https://wiki.rizon.net/index.php?title=CertFP
  # services.matrix-appservice-irc.enable = true;
  services.matrix-appservice-irc.registrationUrl = "http://127.0.0.1:8009";
  # settings documented here: https://github.com/matrix-org/matrix-appservice-irc/blob/develop/config.sample.yaml
  services.matrix-appservice-irc.settings = {
    homeserver = {
      url = "http://127.0.0.1:8008";
      dropMatrixMessagesAfterSecs = 300;
      domain = "uninsane.org";
      enablePresence = true;
      bindPort = 9999;
      bindHost = "127.0.0.1";
    };

    ircService = {
      servers = {
        "irc.rizon.net" = {
          name = "Rizon";
          port = 6697;  # SSL port
          ssl = true;
          sasl = true;  # appservice doesn't support NickServ identification
          botConfig = {
            # bot has no presence in IRC channel; only real Matrix users
            enabled = false;
            # nick = "UninsaneDotOrg";
            nick = "uninsane";
            username = "uninsane";
          };
          dynamicChannels = {
            enabled = true;
            aliasTemplate = "#irc_rizon_$CHANNEL";
          };
          ircClients = {
            nickTemplate = "$LOCALPARTsane";
            # by default, Matrix will convert messages greater than (3) lines into a pastebin-like URL to send to IRC.
            lineLimit = 20;
          };
          matrixClients = {
            userTemplate = "@irc_rizon_$NICK";  # the :uninsane.org part is appended automatically
          };

          # this will let this user message the appservice with `!join #<IRCChannel>` and the rest "Just Works"
          "@colin:uninsane.org" = "admin";

          membershipLists = {
            enabled = true;
            global = {
              ircToMatrix = {
                initial = true;
                incremental = true;
                requireMatrixJoined = false;
              };
              matrixToIrc = {
                initial = true;
                incremental = true;
              };
            };
          };
          # sync room description?
          bridgeInfoState = {
            enabled = true;
            initial = true;
          };

          # hardcoded mappings, for when dynamicChannels fails us. TODO: probably safe to remove these.
          # mappings = {
          #   "#chat" = {
          #     roomIds = [ "!GXJSOTdbtxRboGtDep:uninsane.org" ];
          #   };
          #   # BakaBT requires account registration, which i think means my user needs to be added before the appservice user
          #   "#BakaBT" = {
          #     roomIds = [ "!feZKttuYuHilqPFSkD:uninsane.org" ];
          #   };
          # };
          # for per-user IRC password:
          #   invite @irc_rizon_NickServ:uninsane.org to a DM and type `help`  => register
          #   invite the matrix-appservice-irc user to a DM and type `!help`   => add PW to database
          # passwordEncryptionKeyPath = "/path/to/privkey";  # appservice will generate its own if unspecified
        };
      };
    };
  };

  sops.secrets.matrix_synapse_secrets = {
    sopsFile = ../../../secrets/uninsane.yaml;
    owner = config.users.users.matrix-synapse.name;
  };
}
