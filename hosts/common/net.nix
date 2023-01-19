{ config, lib, pkgs, ... }:

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
  # - `man iwd.config`  for global config
  # - `man iwd.network` for per-SSID config
  # use `iwctl` to control
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    # auto-connect to a stronger network if signal drops below this value
    # bedroom -> bedroom connection is -35 to -40 dBm
    # bedroom -> living room connection is -60 dBm
    General.RoamThreshold = "-52";  # default -70
    General.RoamThreshold5G = "-52";  # default -76
  };

  sane.fs."/var/lib/iwd/.secrets.psk.stamp" = {
    wantedBeforeBy = [ "iwd.service" ];
    generated.acl.mode = "0600";
    # XXX: install-iwd uses sed, but that's part of the default systemd unit path, it seems
    generated.script.script = builtins.readFile ../../scripts/install-iwd + ''
      touch "/var/lib/iwd/.secrets.psk.stamp"
    '';
    generated.script.scriptArgs = [ "/run/secrets/iwd" "/var/lib/iwd" ];
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];
  # TODO: remove this hacky `if` block
  networking.wireguard.interfaces.wg-home = lib.mkIf (config.networking.hostName != "servo") {
    privateKeyFile = config.sops.secrets.wg_home_privkey.path;
    # client IP (TODO: make host-specific)
    ips = [ "10.100.0.20/32" ];
    listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

    peers = [
      {
        # server pubkey
        publicKey = "pWtnKW7f7sNIZQ2M83uJ7cHg3IL1tebE3IoVkCgjkXM=";

        # accept traffic from any IP addr on the other side of the tunnel
        allowedIPs = [ "0.0.0.0/0" ];

        endpoint = "uninsane.org:51820";

        # send keepalives every 25 seconds to keep NAT routes live
        persistentKeepalive = 25;
      }
    ];
  };
}
