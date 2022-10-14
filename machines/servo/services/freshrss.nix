{ config, lib, ... }:
{
  sops.secrets.freshrss_passwd = {
    sopsFile = ../../../secrets/servo.yaml;
    owner = config.users.users.freshrss.name;
    mode = "400";
  };

  users.users.freshrss.uid = config.sane.allocations.freshrss-uid;
  users.groups.freshrss.gid = config.sane.allocations.freshrss-gid;
  services.freshrss.enable = true;
  services.freshrss.baseUrl = "https://rss.uninsane.org";
  services.freshrss.virtualHost = "rss.uninsane.org";
  services.freshrss.passwordFile = config.sops.secrets.freshrss_passwd.path;
}
