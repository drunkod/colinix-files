# config options:
# - <https://github.com/mautrix/signal/blob/master/mautrix_signal/example-config.yaml>
{ config, pkgs, ... }:
{
  services.signald.enable = true;
  services.mautrix-signal.enable = true;
  services.mautrix-signal.environmentFile =
    config.sops.secrets.mautrix_signal_env.path;

  services.mautrix-signal.settings.signal.socket_path = "/run/signald/signald.sock";
  services.mautrix-signal.settings.homeserver.domain = "uninsane.org";
  services.mautrix-signal.settings.bridge.permissions."@colin:uninsane.org" = "admin";
  services.matrix-synapse.settings.app_service_config_files = [
    # auto-created by mautrix-signal service
    "/var/lib/mautrix-signal/signal-registration.yaml"
  ];

  systemd.services.mautrix-signal.serviceConfig = {
    # allow communication to signald
    SupplementaryGroups = [ "signald" ];
    ReadWritePaths = [ "/run/signald" ];
  };

  sane.persist.sys.plaintext = [
    { user = "mautrix-signal"; group = "mautrix-signal"; directory = "/var/lib/mautrix-signal"; }
  ];

  sops.secrets.mautrix_signal_env = {
    sopsFile = ../../../../secrets/servo/mautrix_signal_env.bin;
    format = "binary";
    mode = "0440";
    owner = config.users.users.mautrix-signal.name;
    group = config.users.users.matrix-synapse.name;
  };
}
