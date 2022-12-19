{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.sane.services.dyn-dns;
in
{
  options = {
    sane.services.dyn-dns = {
      enable = mkOption {
        default = false;
        type = types.bool;
      };

      ipPath = mkOption {
        default = "/var/lib/uninsane/wan.txt";
        type = types.str;
        description = "where to store the latest WAN IPv4 address";
      };

      ipCmd = mkOption {
        default = "${pkgs.sane-scripts}/bin/sane-ip-check-router-wan";
        type = types.path;
        description = "command to run to query the current WAN IP";
      };

      interval = mkOption {
        type = types.str;
        default = "10min";
        description = "systemd time string for how frequently to re-check the IP";
      };

      restartOnChange = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "list of systemd unit files to restart when the IP changes";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.dyn-dns = {
      description = "update this host's record of its WAN IP";
      after = [ "network.target" ];
      restartTriggers = [(builtins.toJSON cfg)];
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p $(dirname "${cfg.ipPath}")
        ${cfg.ipCmd} > "${cfg.ipPath}"
      '';
    };

    systemd.timers.dyn-dns = {
      wantedBy = [ "multi-user.target" ];
      timerConfig = {
        OnStartupSec = cfg.interval;
        OnUnitActiveSec = cfg.interval;
      };
    };

    systemd.paths.dyn-dns-watcher = {
      before = [ "dyn-dns.service" ];
      wantedBy = [ "dyn-dns.service" ];
      pathConfig = {
        Unit = "dyn-dns-reactor.service";
        PathChanged = [ cfg.ipPath ];
      };
    };

    systemd.services.dyn-dns-reactor = {
      description = "react to the system's WAN IP changing";
      serviceConfig.Type = "oneshot";
      script = if cfg.restartOnChange != [] then ''
        ${pkgs.systemd}/bin/systemctl restart ${toString cfg.restartOnChange}
      '' else "${pkgs.coreutils}/bin/true";
    };
  };
}
