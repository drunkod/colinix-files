{ pkgs, ... }:
{
  # based on <https://bytes.fyi/real-time-goaccess-reports-with-nginx/>
  # log-format setting can be derived with this tool if custom:
  # - <https://github.com/stockrt/nginx2goaccess>
  # config options:
  # - <https://github.com/allinurl/goaccess/blob/master/config/goaccess.conf>

  systemd.services.goaccess = {
    description = "GoAccess server monitoring";
    serviceConfig = {
      ExecStart = ''
        ${pkgs.goaccess}/bin/goaccess \
          -f /var/log/nginx/public.log \
          --log-format=VCOMBINED \
          --real-time-html \
          --html-refresh=30 \
          --no-query-string \
          --anonymize-ip \
          --ignore-panel=HOSTS \
          --ws-url=wss://sink.uninsane.org:443/ws \
          --port=7890 \
          -o /var/lib/uninsane/sink/index.html
      '';
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Type = "simple";
      Restart = "on-failure";

      # hardening
      WorkingDirectory = "/tmp";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      SystemCallFilter = "~@clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @privileged @reboot @resources @setuid @swap @raw-io";
      ReadOnlyPaths = "/";
      ReadWritePaths = [ "/proc/self" "/var/lib/uninsane/sink" ];
      PrivateDevices = "yes";
      ProtectKernelModules = "yes";
      ProtectKernelTunables = "yes";
    };
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
