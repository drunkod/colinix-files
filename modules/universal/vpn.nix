{ config, ... }:

{
  networking.wg-quick.interfaces.ovpnd = {
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
    privateKeyFile = config.sops.secrets.wg_ovpnd_privkey.path;
    # to start: `systemctl start wg-quick-ovpnd`
    autostart = false;
  };

  sops.secrets."wg_ovpnd_privkey" = {};
}
