{ config, lib, pkgs, ... }:

with lib;
let
  dataDir = "/var/lib/mautrix-signal";
  registrationFile = "${dataDir}/signal-registration.yaml";
  cfg = config.services.mautrix-signal;
  settingsFormat = pkgs.formats.json {};
  settingsFile =
    settingsFormat.generate "mautrix-signal-config.json" cfg.settings;
in
{
  options = {
    services.mautrix-signal = {
      enable = mkEnableOption (lib.mdDoc "Mautrix-Signal, a Matrix-Signal puppeting bridge");

      settings = mkOption rec {
        apply = recursiveUpdate default;
        inherit (settingsFormat) type;
        default = {
          # defaults based on this upstream example config:
          # - <https://github.com/mautrix/signal/blob/master/mautrix_signal/example-config.yaml>
          homeserver = {
            address = "http://localhost:8008";
            software = "standard";
          };

          appservice = rec {
            address = "http://${hostname}:${toString port}";
            hostname = "localhost";
            port = 29328;

            database = "sqlite:///${dataDir}/mautrix-signal.db";
            database_opts = {};
            bot_username = "signalbot";
          };

          bridge = {
            username_template = "signal_{userid}";
            permissions."*" = "relay";
            double_puppet_server_map = {};
            login_shared_secret_map = {};
          };

          logging = {
            version = 1;

            formatters.journal_fmt.format = "%(name)s: %(message)s";
            handlers.journal = {
              class = "systemd.journal.JournalHandler";
              formatter = "journal_fmt";
              SYSLOG_IDENTIFIER = "mautrix-signal";
            };
            # log to systemd instead of file/console
            root = {
              level = "INFO";
              handlers = ["journal"];
            };
          };
        };
        example = literalExpression ''
          {
            homeserver = {
              address = "http://localhost:8008";
              domain = "mydomain.example";
            };

            bridge.permissions = {
              "@admin:mydomain.example" = "admin";
              "mydomain.example" = "user";
            };
          }
        '';
        description = lib.mdDoc ''
          {file}`config.yaml` configuration as a Nix attribute set.
          Configuration options should match those described in
          [example-config.yaml](https://github.com/mautrix/signale/blob/master/mautrix_signal/example-config.yaml).
        '';
      };

      serviceDependencies = mkOption {
        type = with types; listOf str;
        default = optional config.services.matrix-synapse.enable "matrix-synapse.service";
        defaultText = literalExpression ''
          optional config.services.matrix-synapse.enable "matrix-synapse.service"
        '';
        description = lib.mdDoc ''
          List of Systemd services to require and wait for when starting the application service.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.mautrix-signal = {
      description = "Mautrix-Signal, a Matrix-Signal puppeting bridge.";

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ] ++ cfg.serviceDependencies;
      after = [ "network-online.target" ] ++ cfg.serviceDependencies;
      path = [ pkgs.ffmpeg ];  # voice messages need `ffmpeg`

      preStart = ''
        # generate the appservice's registration file if absent
        if [ ! -f '${registrationFile}' ]; then
          ${pkgs.mautrix-signal}/bin/mautrix-signal \
            --generate-registration \
            --base-config='${pkgs.mautrix-signal}/${pkgs.mautrix-signal.pythonModule.sitePackages}/mautrix_signal/example-config.yaml' \
            --config='${settingsFile}' \
            --registration='${registrationFile}'
        fi
      '';

      serviceConfig = {
        Type = "simple";
        Restart = "always";

        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;

        DynamicUser = true;
        PrivateTmp = true;
        StateDirectory = baseNameOf dataDir;
        UMask = "0027";

        ExecStart = ''
          ${pkgs.mautrix-signal}/bin/mautrix-signal \
            --config='${settingsFile}'
        '';
      };
    };
  };
}
