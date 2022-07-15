{ config, ... }:

{
  colinsane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "jellyfin"; group = "jellyfin"; directory = "/var/lib/jellyfin"; }
  ];
  users.users.jellyfin.uid = config.colinsane.allocations.jellyfin-uid;
  users.groups.jellyfin.gid = config.colinsane.allocations.jellyfin-gid;
  services.jellyfin.enable = true;
}
