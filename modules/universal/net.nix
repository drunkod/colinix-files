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

  # the default backend is "wpa_supplicant".
  # wpa_supplicant reliably picks weak APs to connect to.
  # see: <https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/474>
  # iwd is an alternative that shouldn't have this problem
  # docs:
  # - <https://nixos.wiki/wiki/Iwd>
  # - <https://iwd.wiki.kernel.org/networkmanager>
  # use `iwctl` to control
  # networking.wireless.iwd.enable = true;
  # networking.networkmanager.wifi.backend = "iwd";
  # # autoconnect means NM will manage the connecting, not iwd (?)
  # # this lets us reuse nmconnection files, but the result is that we don't connect to the strongest AP anymore
  # networking.networkmanager.extraConfig = ''
  # [device]
  # wifi.iwd.autoconnect=no
  # '';

  sops.secrets."nm-community-university" = {
    sopsFile = ../../secrets/universal/net/community-university.nmconnection.bin;
    format = "binary";
    path = "/etc/NetworkManager/system-connections/nm-community-university.nmconnection";
  };
  sops.secrets."nm-friend-libertarian-dod" = {
    sopsFile = ../../secrets/universal/net/friend-libertarian-dod.nmconnection.bin;
    format = "binary";
    path = "/etc/NetworkManager/system-connections/friend-libertarian-dod.nmconnection";
  };
  sops.secrets."nm-friend-rationalist-empathist" = {
    sopsFile = ../../secrets/universal/net/friend-rationalist-empathist.nmconnection.bin;
    format = "binary";
    path = "/etc/NetworkManager/system-connections/friend-rationalist-empathist.nmconnection";
  };
  sops.secrets."nm-home-bedroom" = {
    sopsFile = ../../secrets/universal/net/home-bedroom.nmconnection.bin;
    format = "binary";
    path = "/etc/NetworkManager/system-connections/home-bedroom.nmconnection";
  };
  sops.secrets."nm-home-shared-24G" = {
    sopsFile = ../../secrets/universal/net/home-shared-24G.nmconnection.bin;
    format = "binary";
    path = "/etc/NetworkManager/system-connections/home-shared-24G.nmconnection";
  };
  sops.secrets."nm-home-shared" = {
    sopsFile = ../../secrets/universal/net/home-shared.nmconnection.bin;
    format = "binary";
    path = "/etc/NetworkManager/system-connections/home-shared.nmconnection";
  };
}
