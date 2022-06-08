{ config, pkgs, ... }:

{
  networking.domain = "uninsane.org";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  # XXX colin: probably don't need this. wlan0 won't be populated unless i touch a value in networking.interfaces.wlan0
  networking.wireless.enable = false;

  # networking.firewall.enable = false;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    25   # SMTP
    80   # HTTP
    143  # IMAP
    443  # HTTPS
    465  # SMTPS (maybe not required?)
    587  # SMTPS/submission (maybe not required?)
    993  # IMAPS
  ];
  # DLNA ports: https://jellyfin.org/docs/general/networking/index.html
  networking.firewall.allowedUDPPorts = [ 1900 7359 ];

  # we need to use externally-visible nameservers in order for VPNs to be able to resolve hosts.
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  # OVPN CONFIG (https://www.ovpn.com):
  # DOCS: https://nixos.wiki/wiki/WireGuard
  networking.wireguard.enable = true;
  networking.wireguard.interfaces.wg0 = {
    privateKeyFile = config.sops.secrets.wg_ovpns_privkey.path;
    # wg is active only in this namespace.
    # run e.g. ip netns exec ovpns <some command like ping/curl/etc, it'll go through wg>
    #   sudo ip netns exec ovpns ping www.google.com
    # note: without the namespace, you'll need to add a specific route through eth0 for the peer (185.157.162.178/32)
    interfaceNamespace = "ovpns";
    preSetup = "${pkgs.iproute2}/bin/ip netns add ovpns || true";
    postShutdown = "${pkgs.iproute2}/bin/ip netns delete ovpns";
    ips = [
      "185.157.162.178/32"
    ];
    peers = [
      {
        publicKey = "SkkEZDCBde22KTs/Hc7FWvDBfdOCQA4YtBEuC3n5KGs=";
        endpoint = "vpn36.prd.amsterdam.ovpn.com:9930";
        allowedIPs = [ "0.0.0.0/0" ];
        # nixOS says this is important for keeping NATs active
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.services.wg0veth = {
    description = "veth pair to allow communication between host and wg0 netns";
    after = [ "wireguard-wg0.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = with pkgs; writeScript "wg0veth-start" ''
        #!${bash}/bin/bash
        # create veth pair
        ${iproute2}/bin/ip link add ovpns-veth-a type veth peer name ovpns-veth-b
        ${iproute2}/bin/ip addr add 10.0.1.5/24 dev ovpns-veth-a
        ${iproute2}/bin/ip link set ovpns-veth-a up
        # mv veth-b into the ovpns namespace
        ${iproute2}/bin/ip link set ovpns-veth-b netns ovpns
        ${iproute2}/bin/ip -n ovpns addr add 10.0.1.6/24 dev ovpns-veth-b
        ${iproute2}/bin/ip -n ovpns link set ovpns-veth-b up
        # forward HTTP traffic, which we need for letsencrypt to work
        ${iproute2}/bin/ip netns exec ovpns ${socat}/bin/socat TCP4-LISTEN:80,reuseaddr,fork,su=nobody TCP4:10.0.1.5:80 &
      '';

      ExecStop = with pkgs; writeScript "wg0veth-stop" ''
        #!${bash}/bin/bash
        ${iproute2}/bin/ip -n wg0 link del ovpns-veth-b
        ${iproute2}/bin/ip link del ovpns-veth-a
      '';
    };
  };

  sops.secrets."wg_ovpns_privkey" = {
    sopsFile = ../../secrets/uninsane.yaml;
  };

  # HURRICANE ELECTRIC CONFIG:
  # networking.sits = {
  #   hurricane = {
  #     remote = "216.218.226.238";
  #     local = "192.168.0.5";
  #     # local = "10.0.0.5";
  #     # remote = "10.0.0.1";
  #     # local = "10.0.0.22";
  #     dev = "eth0";
  #     ttl = 255;
  #   };
  # };
  # networking.interfaces."hurricane".ipv6 = {
  #   addresses = [
  #     # mx.uninsane.org (publically routed /64)
  #     {
  #       address = "2001:470:b:465::1";
  #       prefixLength = 128;
  #     }
  #     # client addr
  #     # {
  #     #   address = "2001:470:a:466::2";
  #     #   prefixLength = 64;
  #     # }
  #   ];
  #   routes = [
  #     {
  #       address = "::";
  #       prefixLength = 0;
  #       # via = "2001:470:a:466::1";
  #     }
  #   ];
  # };

  # # after configuration, we want the hurricane device to look like this:
  # # hurricane: flags=209<UP,POINTOPOINT,RUNNING,NOARP>  mtu 1480
  # #            inet6 2001:470:a:450::2  prefixlen 64  scopeid 0x0<global>
  # #            inet6 fe80::c0a8:16  prefixlen 64  scopeid 0x20<link>
  # #            sit  txqueuelen 1000  (IPv6-in-IPv4)
  # # test with:
  # #   curl --interface hurricane http://[2607:f8b0:400a:80b::2004]
  # #   ping 2607:f8b0:400a:80b::2004
}
