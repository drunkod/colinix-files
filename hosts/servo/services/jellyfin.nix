{ config, ... }:

{
  sane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "jellyfin"; group = "jellyfin"; directory = "/var/lib/jellyfin"; }
  ];

  # users.users.jellyfin.uid = config.sane.allocations.jellyfin-uid;
  # users.groups.jellyfin.gid = config.sane.allocations.jellyfin-gid;
  # TODO: re-enable after migrating media dir to /var/lib/uninsane/media
  # else it's too spammy
  # services.jellyfin.enable = true;
}
