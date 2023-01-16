{ pkgs, ... }:
{
  services.signald.enable = true;
  services.mautrix-signal.enable = true;

  services.matrix-synapse.settings.app_service_config_files = [
    # auto-created by mautrix-signal service
    "/var/lib/mautrix-signal/signal-registration.yaml"
  ];
}
