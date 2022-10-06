# admin:
# - view stats:
#   - sudo -u ipfs -g ipfs ipfs -c /var/lib/ipfs/ stats bw
#   - sudo -u ipfs -g ipfs ipfs -c /var/lib/ipfs/ stats dht
#   - sudo -u ipfs -g ipfs ipfs -c /var/lib/ipfs/ bitswap stat
# - number of open peer connections:
#   - sudo -u ipfs -g ipfs ipfs -c /var/lib/ipfs/ swarm peers | wc -l

{ ... }:
{
  sane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "261"; group = "261"; directory = "/var/lib/ipfs"; }
  ];
  # services.ipfs.enable = true;
  services.ipfs.localDiscovery = true;
  services.ipfs.swarmAddress = [
    # "/dns4/ipfs.uninsane.org/tcp/4001"
    # "/ip4/0.0.0.0/tcp/4001"
    "/dns4/ipfs.uninsane.org/udp/4001/quic"
    "/ip4/0.0.0.0/udp/4001/quic"
  ];
  services.ipfs.extraConfig = {
    Addresses = {
      Announce = [
        # "/dns4/ipfs.uninsane.org/tcp/4001"
        "/dns4/ipfs.uninsane.org/udp/4001/quic"
      ];
    };
    Gateway = {
      # the gateway can only be used to serve content already replicated on this host
      NoFetch = true;
    };
    Swarm = {
      ConnMgr = {
        # maintain between LowWater and HighWater peer connections
        # taken from: https://github.com/ipfs/ipfs-desktop/pull/2055
        # defaults are 600-900: https://github.com/ipfs/kubo/blob/master/docs/config.md#swarmconnmgr
        LowWater = 20;
        HighWater = 40;
        # default is 20s. i guess more grace period = less churn
        GracePeriod = "1m";
      };
      ResourceMgr = {
        # docs: https://github.com/libp2p/go-libp2p-resource-manager#resource-scopes
        Enabled = true;
        Limits = {
          System = {
            Conns = 196;
            ConnsInbound = 128;
            ConnsOutbound = 128;
            FD = 512;
            Memory = 1073741824;  # 1GiB
            Streams = 1536;
            StreamsInbound = 1024;
            StreamsOutbound = 1024;
          };
        };
      };
      Transports = {
        Network = {
          # disable TCP, force QUIC, for lighter resources
          TCP = false;
          QUIC = true;
        };
      };
    };
  };
}
