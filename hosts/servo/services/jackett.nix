{ ... }:

{
  sane.impermanence.service-dirs = [
    # TODO: mode? we only need this to save Indexer creds ==> migrate to config?
    { user = "root"; group = "root"; directory = "/var/lib/jackett"; }
  ];
  services.jackett.enable = true;

  systemd.services.jackett.after = ["wg0veth.service"];
  systemd.services.jackett.serviceConfig = {
    # run this behind the OVPN static VPN
    NetworkNamespacePath = "/run/netns/ovpns";
    # patch jackett to listen on the public interfaces
    # ExecStart = lib.mkForce "${pkgs.jackett}/bin/Jackett --NoUpdates --DataFolder /var/lib/jackett/.config/Jackett --ListenPublic";
  };
}

