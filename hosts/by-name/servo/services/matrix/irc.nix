{ config, lib, ... }:

{
  sane.persist.sys.plaintext = [
    # TODO: mode?
    { user = "matrix-appservice-irc"; group = "matrix-appservice-irc"; directory = "/var/lib/matrix-appservice-irc"; }
  ];

  services.matrix-synapse.settings.app_service_config_files = [
    "/var/lib/matrix-appservice-irc/registration.yml"  # auto-created by irc appservice
  ];

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
          sasl = true;  # appservice doesn't support NickServ identification
          botConfig = {
            # bot has no presence in IRC channel; only real Matrix users
            enabled = false;
            # this is the IRC username/nickname *of the bot* (not visible in channels): not of the end-user.
            # the irc username/nick of a mapped Matrix user is determined further down in `ircClients` section.
            # nick = "UninsaneDotOrg";
            nick = "uninsane";
            username = "uninsane";
          };
          dynamicChannels = {
            enabled = true;
            aliasTemplate = "#irc_rizon_$CHANNEL";
          };
          ircClients = {
            nickTemplate = "$LOCALPARTsane";  # @colin:uninsane.org (Matrix) -> colinsane (IRC)
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

          # for per-user IRC password:
          # - invite @irc_rizon_NickServ:uninsane.org to a DM and type `help`  => register
          # - invite the matrix-appservice-irc user to a DM and type `!help`   => add PW to database
          # to validate that i'm authenticated on the IRC network, DM @irc_rizon_NickServ:uninsane.org:
          # - send: `STATUS colinsane`
          # - response should be `3`: "user recognized as owner via password identification"
          # passwordEncryptionKeyPath = "/path/to/privkey";  # appservice will generate its own if unspecified
        };
      };
    };
  };
}
