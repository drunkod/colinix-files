{ ... }:

{
  sane.impermanence.service-dirs = [
    # TODO: mode? we need this specifically for the stats tracking in .config/
    { user = "70"; group = "70"; directory = "/var/lib/transmission"; }
  ];
  services.transmission.enable = true;
  services.transmission.settings = {
    rpc-bind-address = "0.0.0.0";
    #rpc-host-whitelist = "bt.uninsane.org";
    #rpc-whitelist = "*.*.*.*";
    rpc-authentication-required = true;
    rpc-username = "colin";
    # salted pw. to regenerate, set this plaintext, run nixos-rebuild, and then find the salted pw in:
    # /var/lib/transmission/.config/transmission-daemon/settings.json
    rpc-password = "{503fc8928344f495efb8e1f955111ca5c862ce0656SzQnQ5";
    rpc-whitelist-enabled = false;

    # download-dir = "/opt/uninsane/media/";
    # hopefully, make the downloads world-readable
    umask = 0;

    # force peer connections to be encrypted
    encryption = 2;

    # units in kBps
    speed-limit-down = 3000;
    speed-limit-down-enabled = true;
    speed-limit-up = 300;
    speed-limit-up-enabled = true;

    # see: https://git.zknt.org/mirror/transmission/commit/cfce6e2e3a9b9d31a9dafedd0bdc8bf2cdb6e876?lang=bg-BG
    anti-brute-force-enabled = false;

    download-dir = "/var/lib/uninsane/media";
    incomplete-dir = "/var/lib/uninsane/media/incomplete";

  };
  # transmission will by default not allow the world to read its files.
  services.transmission.downloadDirPermissions = "775";

  systemd.services.transmission.after = ["wg0veth.service"];
  systemd.services.transmission.serviceConfig = {
    # run this behind the OVPN static VPN
    NetworkNamespacePath = "/run/netns/ovpns";
  };
}

