{ config, ... }:

{
  # if using router's DNS, these mappings will already exist.
  # if using a different DNS provider (which servo does), then we need to explicity provide them.
  # ugly hack. would be better to get servo to somehow use the router's DNS
  networking.hosts = {
    "192.168.0.5" = [ "servo" ];
    "192.168.0.20" = [ "lappy" ];
    "192.168.0.22" = [ "desko" ];
    "192.168.0.48" = [ "moby" ];
  };

  sops.secrets."nm-community-university" = {
    sopsFile = ../../secrets/universal/net/community-university.nmconnection.bin;
    format = "binary";
  };
  sops.secrets."nm-friend-libertarian-dod" = {
    sopsFile = ../../secrets/universal/net/friend-libertarian-dod.nmconnection.bin;
    format = "binary";
  };
  sops.secrets."nm-friend-rationalist-empathist" = {
    sopsFile = ../../secrets/universal/net/friend-rationalist-empathist.nmconnection.bin;
    format = "binary";
  };
  sops.secrets."nm-home-bedroom" = {
    sopsFile = ../../secrets/universal/net/home-bedroom.nmconnection.bin;
    format = "binary";
  };
  sops.secrets."nm-home-shared-24G" = {
    sopsFile = ../../secrets/universal/net/home-shared-24G.nmconnection.bin;
    format = "binary";
  };
  sops.secrets."nm-home-shared" = {
    sopsFile = ../../secrets/universal/net/home-shared.nmconnection.bin;
    format = "binary";
  };

  environment.etc = {
    "NetworkManager/system-connections/nm-community-university".source = config.sops.secrets.nm-community-university.path;
    "NetworkManager/system-connections/nm-friend-libertarian-dod".source = config.sops.secrets.nm-friend-libertarian-dod.path;
    "NetworkManager/system-connections/nm-friend-rationalist-empathist".source = config.sops.secrets.nm-friend-rationalist-empathist.path;
    "NetworkManager/system-connections/nm-home-bedroom".source = config.sops.secrets.nm-home-bedroom.path;
    "NetworkManager/system-connections/nm-home-shared-24G".source = config.sops.secrets.nm-home-shared-24G.path;
    "NetworkManager/system-connections/nm-home-shared".source = config.sops.secrets.nm-home-shared.path;
  };
}
