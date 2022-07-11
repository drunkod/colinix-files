{ ... }:

{
  colinsane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "996"; group = "994"; directory = "/var/lib/jellyfin"; }
  ];
  services.jellyfin.enable = true;
}
