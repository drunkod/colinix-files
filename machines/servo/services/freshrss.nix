# import feeds with e.g.
# sudo -u freshrss -g freshrss FRESHRSS_DATA_PATH=/var/lib/freshrss ./result/cli/import-for-user.php --user admin --filename /home/colin/.config/newsflashFeeds.opml

{ config, lib, ... }:
{
  sops.secrets.freshrss_passwd = {
    sopsFile = ../../../secrets/servo.yaml;
    owner = config.users.users.freshrss.name;
    mode = "400";
  };
  sane.impermanence.service-dirs = [
    { user = "freshrss"; group = "freshrss"; directory = "/var/lib/freshrss"; }
  ];

  users.users.freshrss.uid = config.sane.allocations.freshrss-uid;
  users.groups.freshrss.gid = config.sane.allocations.freshrss-gid;
  services.freshrss.enable = true;
  services.freshrss.baseUrl = "https://rss.uninsane.org";
  services.freshrss.virtualHost = "rss.uninsane.org";
  services.freshrss.passwordFile = config.sops.secrets.freshrss_passwd.path;
}
