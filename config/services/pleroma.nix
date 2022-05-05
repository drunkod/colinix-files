# docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/pleroma.nix
#
# to run it in a oci-container: https://github.com/barrucadu/nixfiles/blob/master/services/pleroma.nix
{ config, pkgs, lib, ... }:

{
  services.pleroma.enable = true;
  # XXX colin: this isn't checked into git, so make sure to create it first:
  services.pleroma.secretConfigFile = "/etc/nixos/secrets/pleroma.secret.exs";
  # services.pleroma.secretConfigFile = "/var/lib/pleroma/prod.secret.exs";
  services.pleroma.configs = [
    ''
    import Config
    
    config :pleroma, Pleroma.Web.Endpoint,
      url: [host: "fed.uninsane.org", scheme: "https", port: 443],
      http: [ip: {127, 0, 0, 1}, port: 4000]
    
    config :pleroma, :instance,
      name: "Perfectly Sane",
      email: "dev@null",
      notify_email: "dev@null",
      limit: 5000,
      registrations_open: false
    
    config :pleroma, :media_proxy,
      enabled: false,
      redirect_on_failure: true
      #base_url: "https://cache.pleroma.social"
    
    config :pleroma, Pleroma.Repo,
      adapter: Ecto.Adapters.Postgres,
      username: "pleroma",
      database: "pleroma",
      hostname: "localhost",
      pool_size: 10,
      prepare: :named,
      parameters: [
          plan_cache_mode: "force_custom_plan"
      ]
    
    config :pleroma, :database, rum_enabled: false
    # config :pleroma, :instance, static_dir: "/mnt/storage/opt/pleroma.nix/instance/static"
    # config :pleroma, Pleroma.Uploaders.Local, uploads: "/mnt/storage/opt/pleroma.nix/uploads"
    config :pleroma, :instance, static_dir: "/var/lib/pleroma/instance/static"
    config :pleroma, Pleroma.Uploaders.Local, uploads: "/var/lib/pleroma/uploads"
    config :pleroma, configurable_from_database: false

    config :pleroma, Pleroma.Upload, filters: [Pleroma.Upload.Filter.Exiftool]


    # (enabled by colin)
    # Enable Strict-Transport-Security once SSL is working:
    config :pleroma, :http_security,
      sts: true
    
    # (added by colin; based on https://docs.pleroma.social/backend/configuration/cheatsheet/#logger)
    config :logger,
      backends: [{ExSyslogger, :ex_syslogger}]
    
    config :logger, :ex_syslogger,
      level: :warn
    ''
  ];

  systemd.services.pleroma.path = [ 
    # something inside pleroma invokes `sh` w/o specifying it by path, so this is needed to allow pleroma to start
    pkgs.bash 
    # used by Pleroma to strip geo tags from uploads
    pkgs.exiftool 
  ];
}
