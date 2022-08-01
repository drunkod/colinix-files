{ ... }:
{
  sane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "261"; group = "261"; directory = "/var/lib/ipfs"; }
  ];
  services.ipfs.enable = true;
  services.ipfs.localDiscovery = true;
  services.ipfs.swarmAddress = [
    "/dns4/ipfs.uninsane.org/tcp/4001"
    "/ip4/0.0.0.0/tcp/4001"
    "/dns4/ipfs.uninsane.org/udp/4001/quic"
    "/ip4/0.0.0.0/udp/4001/quic"
  ];
  services.ipfs.extraConfig = {
    Addresses = {
      Announce = [
        "/dns4/ipfs.uninsane.org/tcp/4001"
        "/dns4/ipfs.uninsane.org/udp/4001/quic"
      ];
    };
    Gateway = {
      # the gateway can only be used to serve content already replicated on this host
      NoFetch = true;
    };
  };
}
