{ ... }:

{
  colinsane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "jellyfin"; group = "jellyfin"; directory = "/var/lib/jellyfin"; }
  ];
  users.users.jellyfin.uid = 996;
  users.groups.jellyfin.gid = 994;
  services.jellyfin.enable = true;
}
