# docs: https://nixos.wiki/wiki/Matrix
# docs: https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
{ config, pkgs, lib, ... }:

{
  services.matrix-synapse.enable = true;
  services.matrix-synapse.server_name = "uninsane.org";

  # services.matrix-synapse.enable_registration_captcha = true;
  # services.matrix-synapse.enable_registration_without_verification = true;
  services.matrix-synapse.enable_registration = true;
  # services.matrix-synapse.registration_shared_secret = "<shared key goes here>";

  # default for listeners is port = 8448, tls = true, x_forwarded = false.
  # we change this because the server is situated behind nginx.
  services.matrix-synapse.listeners = [
    {
      port = 8008;
      bind_address = "127.0.0.1";
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

  services.matrix-synapse.extraConfig = ''
    registration_requires_token: true
  '';
  services.matrix-synapse.app_service_config_files = [
    "/var/lib/matrix-appservice-irc/registration.yml"  # auto-created by irc appservice
  ];

  # new users may be registered on the CLI:
  # register_new_matrix_user -c /nix/store/8n6kcka37jhmi4qpd2r03aj71pkyh21s-homeserver.yaml http://localhost:8008

  # IRC bridging
  # note: Rizon allows only FOUR simultaneous IRC connections per IP: https://wiki.rizon.net/index.php?title=Connection/Session_Limit_Exemptions
  # Rizon supports CertFP for auth: https://wiki.rizon.net/index.php?title=CertFP
  services.matrix-appservice-irc.enable = true;
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
          sasl = false;  # just use plain auth
          botConfig = {
            # bot has no presence in IRC channel; only real Matrix users
            enabled = false;
            nick = "UninsaneDotOrg";
            username = "uninsane";
          };
          dynamicChannels = {
            enabled = true;
            aliasTemplate = "#irc_rizon_$CHANNEL";
          };
          ircClients = {
            nickTemplate = "$LOCALPART_uninsane";
            # by default, Matrix will convert messages greater than (3) lines into a pastebin-like URL to send to IRC.
            lineLimit = 20;
          };
          matrixClients = {
            userTemplate = "@irc_rizon_$NICK";  # the :uninsane.org part is appended automatically
          };

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

          # hardcoded mappings, for when dynamicChannels fails us :-(
          mappings = {
            "#chat" = {
              roomIds = [ "!GXJSOTdbtxRboGtDep:uninsane.org" ];
            };
          };
          # passwordEncryptionKeyPath = "/path/to/privkey";
        };
      };
    };
  };
}
