{ config, pkgs, ... }:
{
  services.signald.enable = true;
  services.mautrix-signal.enable = true;
  services.mautrix-signal.environmentFile =
    config.sops.secrets.mautrix_signal_env.path;

  services.mautrix-signal.settings.homeserver.domain = "uninsane.org";
  services.matrix-synapse.settings.app_service_config_files = [
    # auto-created by mautrix-signal service
    "/var/lib/mautrix-signal/signal-registration.yaml"
  ];

  sops.secrets.mautrix_signal_env = {
    sopsFile = ../../../../secrets/servo/mautrix_signal_env.bin;
    format = "binary";
    mode = "0440";
    owner = config.users.users.mautrix-signal.name;
    group = config.users.users.matrix-synapse.name;
  };
}
