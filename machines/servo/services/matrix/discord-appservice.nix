{ config, lib, ... }:

{
  sane.impermanence.service-dirs = [
    { user = "matrix-appservice-discord"; group = "matrix-appservice-discord"; directory = "/var/lib/matrix-appservice-discord"; }
  ];

  sops.secrets.matrix_appservice_discord_env = {
    sopsFile = ../../../../secrets/servo/matrix_appservice_discord_env.bin;
    owner = config.users.users.matrix-appservice-discord.name;
    format = "binary";
  };

  services.matrix-synapse.settings.app_service_config_files = [
    # auto-created by discord appservice
    "/var/lib/matrix-appservice-discord/discord-registration.yaml"
  ];

  # Discord bridging
  # docs: https://github.com/matrix-org/matrix-appservice-discord
  services.matrix-appservice-discord.enable = true;
  services.matrix-appservice-discord.settings = {
    bridge = {
      homeserverUrl = "http://127.0.0.1:8008";
      domain = "uninsane.org";
      adminMxid = "admin.matrix@uninsane.org";
      # self-service bridging is when a Matrix user bridges by DMing @_discord_bot:<HS>
      # i don't know what the alternative is :?
      enableSelfServiceBridging = true;
      presenceInterval = 30000; # milliseconds
      # allows matrix users to search for Discord channels (somehow?)
      disablePortalBridging = false;
      # disableReadReceipts = true;
      # these are Matrix -> Discord
      disableJoinLeaveNotifications = true;
      disableInviteNotifications = true;
      disableRoomTopicNotifications = true;
    };
    # these are marked as required in the yaml schema
    auth = {
      # apparently not needed if you provide them as env vars (below).
      # clientId = "FILLME";
      # botToken = "FILLME";
      usePrivilegedIntents = false;
    };
    logging = {
      # silly, verbose, info, http, warn, error, silent
      console = "verbose";
    };
  };
  # contains what's ordinarily put into auth.clientId, auth.botToken
  # i.e. `APPSERVICE_DISCORD_AUTH_CLIENT_I_D=...` and `APPSERVICE_DISCORD_AUTH_BOT_TOKEN=...`
  services.matrix-appservice-discord.environmentFile = config.sops.secrets.matrix_appservice_discord_env.path;

  systemd.services.matrix-appservice-discord.serviceConfig = {
    # fix up to not use /var/lib/private, but just /var/lib
    DynamicUser = lib.mkForce false;
    User = "matrix-appservice-discord";
    Group = "matrix-appservice-discord";
  };
  users.groups.matrix-appservice-discord = {};
  users.users.matrix-appservice-discord = {
    description = "User for the Matrix-Discord bridge";
    group = "matrix-appservice-discord";
    isSystemUser = true;
  };
  users.users.matrix-appservice-discord.uid = 2134;  # TODO: move to allocations
  users.groups.matrix-appservice-discord.gid = 2134;  # TODO
}
