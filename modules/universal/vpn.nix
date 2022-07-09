{ config, ... }:

{
  networking.wg-quick.interfaces.ovpnd-us = {
    address = [
      "172.27.237.218/32"
      "fd00:0000:1337:cafe:1111:1111:ab00:4c8f/128"
    ];
    dns = [
      "46.227.67.134"
      "192.165.9.158"
    ];
    peers = [
      {
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        endpoint = "vpn31.prd.losangeles.ovpn.com:9929";
        publicKey = "VW6bEWMOlOneta1bf6YFE25N/oMGh1E1UFBCfyggd0k=";
      }
    ];
    privateKeyFile = config.sops.secrets.wg_ovpnd_us_privkey.path;
    # to start: `systemctl start wg-quick-ovpnd-us`
    autostart = false;
  };

  networking.wg-quick.interfaces.ovpnd-ukr = {
    address = [
      "172.18.180.159/32"
      "fd00:0000:1337:cafe:1111:1111:ec5c:add3/128"
    ];
    dns = [
      "46.227.67.134"
      "192.165.9.158"
    ];
    peers = [
      {
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        endpoint = "vpn96.prd.kyiv.ovpn.com:9929";
        publicKey = "CjZcXDxaaKpW8b5As1EcNbI6+42A6BjWahwXDCwfVFg=";
      }
    ];
    privateKeyFile = config.sops.secrets.wg_ovpnd_ukr_privkey.path;
    # to start: `systemctl start wg-quick-ovpnd-ukr`
    autostart = false;
  };

  sops.secrets."wg_ovpnd_us_privkey" = {
    sopsFile = ../../secrets/universal.yaml;
  };
  sops.secrets."wg_ovpnd_ukr_privkey" = {
    sopsFile = ../../secrets/universal.yaml;
  };
}
