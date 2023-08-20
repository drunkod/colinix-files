# docs:
# - <repo:LemmyNet/lemmy:docker/federation/nginx.conf>
# - <repo:LemmyNet/lemmy:docker/nginx.conf>
# - <repo:LemmyNet/lemmy-ansible:templates/nginx.conf>

{ config, lib, pkgs, ... }:
let
  inherit (builtins) toString;
  inherit (lib) mkForce;
  uiPort = 1234;  # default ui port is 1234
  backendPort = 8536; # default backend port is 8536
  #^ i guess the "backend" port is used for federation?
  pict-rs = pkgs.pict-rs.overrideAttrs (upstream: {
    # as of v 0.4.2, all non-GIF video is forcibly transcoded.
    # that breaks lemmy, because of the request latency.
    # and it eats up hella CPU.
    # pict-rs is iffy around video altogether: mp4 seems the best supported.
    postPatch = (upstream.postPatch or "") + ''
      substituteInPlace src/validate.rs \
        --replace 'if transcode_options.needs_reencode() {' 'if false {'
    '';
  });
in {
  services.lemmy = {
    enable = true;
    settings.hostname = "lemmy.uninsane.org";
    # federation.debug forces outbound federation queries to be run synchronously
    # N.B.: this option might not be read for 0.17.0+? <https://github.com/LemmyNet/lemmy/blob/c32585b03429f0f76d1e4ff738786321a0a9df98/RELEASES.md#upgrade-instructions>
    # settings.federation.debug = true;
    settings.port = backendPort;
    ui.port = uiPort;
    database.createLocally = true;
    nginx.enable = true;
  };

  systemd.services.lemmy.serviceConfig = {
    # fix to use a normal user so we can configure perms correctly
    DynamicUser = mkForce false;
    User = "lemmy";
    Group = "lemmy";
  };
  systemd.services.lemmy.environment = {
    RUST_BACKTRACE = "full";
    # RUST_LOG = "debug";
    # RUST_LOG = "trace";
    # upstream defaults LEMMY_DATABASE_URL = "postgres:///lemmy?host=/run/postgresql";
    # - Postgres complains that we didn't specify a user
    # lemmy formats the url as:
    # - postgres://{user}:{password}@{host}:{port}/{database}
    # SO suggests (https://stackoverflow.com/questions/3582552/what-is-the-format-for-the-postgresql-connection-string-url):
    # - postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]
    # LEMMY_DATABASE_URL = "postgres://lemmy@/run/postgresql";  # connection to server on socket "/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "run/postgresql" does not exist
    # LEMMY_DATABASE_URL = "postgres://lemmy?host=/run/postgresql";  # no PostgreSQL user name specified in startup packet
    # LEMMY_DATABASE_URL = mkForce "postgres://lemmy@?host=/run/postgresql";  # WORKS
    LEMMY_DATABASE_URL = mkForce "postgres://lemmy@/lemmy?host=/run/postgresql";
  };
  users.groups.lemmy = {};
  users.users.lemmy = {
    group = "lemmy";
    isSystemUser = true;
  };

  services.nginx.virtualHosts."lemmy.uninsane.org" = {
    forceSSL = true;
    enableACME = true;
  };

  sane.dns.zones."uninsane.org".inet.CNAME."lemmy" = "native";

  #v DO NOT REMOVE: defaults to 0.3, instead of latest, so always need to explicitly set this.
  services.pict-rs.package = pict-rs;
  # pict-rs configuration is applied in this order:
  # - via toml
  # - via env vars (overrides everything above)
  # - via CLI flags (overrides everything above)
  # some of the CLI flags have defaults, making it the only actual way to configure certain things even when docs claim otherwise.
  systemd.services.pict-rs.environment = {
    # lemmy's media-hosting service
    # docs: <https://git.asonix.dog/asonix/pict-rs/src/branch/main/pict-rs.toml>

    # PICTRS__MEDIA__VIDEO__ENABLE = "1";  # enable webm and mp4
    # PICTRS__MEDIA__VIDEO__ALLOW_AUDIO = "1";
    # PICTRS__MEDIA__VIDEO__MAX_FRAME_COUNT = builtins.toString (30*60*60);  # ~ 1 hr
    # PICTRS__REPO__CACHE_CAPACITY = builtins.toString (128*1024*1024);  # default is 64 MiB, but RAM is cheap here

    # PICTRS__MEDIA__SKIP_VALIDATE_IMPORTS = "1";  # to disable media validation
    # PICTRS__OLD_DB__PATH = config.services.pict-rs.dataDir;  #< needed only for 0.3 -> 0.4 migration
  };
  # CLI args: <https://git.asonix.dog/asonix/pict-rs#user-content-running>
  systemd.services.pict-rs.serviceConfig.ExecStart = lib.mkForce (lib.concatStringsSep " " [
    "${lib.getBin pict-rs}/bin/pict-rs run"
    "--media-max-frame-count" (builtins.toString (30*60*60))
    "--media-process-timeout 120"
    "--media-enable-full-video true"  # allow audio
  ]);
}
