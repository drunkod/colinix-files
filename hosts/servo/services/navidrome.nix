{ ... }:

{
  sane.impermanence.service-dirs = [
    { user = "navidrome"; group = "navidrome"; directory = "/var/lib/private/navidrome"; }
  ];
  services.navidrome.enable = true;
  services.navidrome.settings = {
    # docs: https://www.navidrome.org/docs/usage/configuration-options/
    Address = "127.0.0.1";
    Port = 4533;
    MusicFolder = "/var/lib/uninsane/media/Music";
    CovertArtPriority = "*.jpg, *.JPG, *.png, *.PNG, embedded";
    AutoImportPlaylists = false;
    ScanSchedule = "@every 1h";
  };
}
