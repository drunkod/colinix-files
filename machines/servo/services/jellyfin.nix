{ config, ... }:

{
  sane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "jellyfin"; group = "jellyfin"; directory = "/var/lib/jellyfin"; }
  ];
  users.users.jellyfin.uid = config.sane.allocations.jellyfin-uid;
  users.groups.jellyfin.gid = config.sane.allocations.jellyfin-gid;
  services.jellyfin.enable = true;
}
