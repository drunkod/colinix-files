{ ... }:

{
  sane.impermanence.dirs.sys.plaintext = [
    # TODO: we don't have a static user allocated for navidrome!
    # the chown would happen too early for us to set static perms
    "/var/lib/private/navidrome"
    # { user = "navidrome"; group = "navidrome"; directory = "/var/lib/private/navidrome"; }
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

  services.nginx.virtualHosts."music.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
    # inherit kTLS;
    locations."/".proxyPass = "http://127.0.0.1:4533";
  };

  sane.services.trust-dns.zones."uninsane.org".inet.CNAME."music" = "native";
}
