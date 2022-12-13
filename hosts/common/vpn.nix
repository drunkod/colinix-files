{ config, ... }:

let
  def-ovpn = { endpoint, publicKey, privateKeyFile, address }:  {
    inherit address privateKeyFile;
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
        inherit endpoint publicKey;
      }
    ];
    # to start: `systemctl start wg-quick-ovpnd-{region}`
    autostart = false;
  };
in {
  # to add a new OVPN VPN:
  # - generate a privkey `wg genkey`
  # - add this key to `sops secrets/universal.yaml`
  # - upload pubkey to OVPN.com
  # - generate config @ OVPN.com
  # - copy the Address, PublicKey, Endpoint from OVPN's config
  networking.wg-quick.interfaces.ovpnd-us = def-ovpn {
    endpoint = "vpn31.prd.losangeles.ovpn.com:9929";
    publicKey = "VW6bEWMOlOneta1bf6YFE25N/oMGh1E1UFBCfyggd0k=";
    privateKeyFile = config.sops.secrets.wg_ovpnd_us_privkey.path;
    address = [
      "172.27.237.218/32"
      "fd00:0000:1337:cafe:1111:1111:ab00:4c8f/128"
    ];
  };
  networking.wg-quick.interfaces.ovpnd-us-atlanta = def-ovpn {
    endpoint = "vpn18.prd.atlanta.ovpn.com:9929";
    publicKey = "Dpg/4v5s9u0YbrXukfrMpkA+XQqKIFpf8ZFgyw0IkE0=";
    privateKeyFile = config.sops.secrets.wg_ovpnd_us_atlanta_privkey.path;
    address = [
      "172.21.182.178/32"
      "fd00:0000:1337:cafe:1111:1111:cfcb:27e3/128"
    ];
  };

  networking.wg-quick.interfaces.ovpnd-ukr = def-ovpn {
    endpoint = "vpn96.prd.kyiv.ovpn.com:9929";
    publicKey = "CjZcXDxaaKpW8b5As1EcNbI6+42A6BjWahwXDCwfVFg=";
    privateKeyFile = config.sops.secrets.wg_ovpnd_ukr_privkey.path;
    address = [
      "172.18.180.159/32"
      "fd00:0000:1337:cafe:1111:1111:ec5c:add3/128"
    ];
  };

  sops.secrets."wg_ovpnd_us_privkey" = {
    sopsFile = ../../secrets/universal.yaml;
  };
  sops.secrets."wg_ovpnd_us_atlanta_privkey" = {
    sopsFile = ../../secrets/universal.yaml;
  };
  sops.secrets."wg_ovpnd_ukr_privkey" = {
    sopsFile = ../../secrets/universal.yaml;
  };
}
