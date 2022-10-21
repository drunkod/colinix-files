{ config, ... }:
{
  services.munin-node.enable = true;
  services.munin-cron = {
    enable = true;
    # collect data from the localhost
    hosts = ''
      [${config.networking.hostName}]
      address localhost
    '';
  };
}
