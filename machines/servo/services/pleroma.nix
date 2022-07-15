# docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/pleroma.nix
#
# to run it in a oci-container: https://github.com/barrucadu/nixfiles/blob/master/services/pleroma.nix
{ config, pkgs, ... }:

{
  colinsane.impermanence.service-dirs = [
    # TODO: mode? could be more granular
    { user = "pleroma"; group = "pleroma"; directory = "/var/lib/pleroma"; }
  ];
  users.users.pleroma.uid = 997;
  users.groups.pleroma.gid = 995;
  services.pleroma.enable = true;
  services.pleroma.secretConfigFile = config.sops.secrets.pleroma_secrets.path;
  services.pleroma.configs = [
    ''
    import Config
    
    config :pleroma, Pleroma.Web.Endpoint,
      url: [host: "fed.uninsane.org", scheme: "https", port: 443],
      http: [ip: {127, 0, 0, 1}, port: 4000]
    #   secret_key_base: "{secrets.pleroma.secret_key_base}",
    #   signing_salt: "{secrets.pleroma.signing_salt}"
    
    config :pleroma, :instance,
      name: "Perfectly Sane",
      description: "Single-user Pleroma instance",
      email: "admin.pleroma@uninsane.org",
      notify_email: "notify.pleroma@uninsane.org",
      limit: 5000,
      registrations_open: true,
      account_approval_required: true,
      max_pinned_statuses: 5,
      external_user_synchronization: true

    # docs: https://hexdocs.pm/swoosh/Swoosh.Adapters.Sendmail.html
    # test mail config with sudo -u pleroma ./bin/pleroma_ctl email test --to someone@somewhere.net
    config :pleroma, Pleroma.Emails.Mailer,
      enabled: true,
      adapter: Swoosh.Adapters.Sendmail,
      cmd_path: "${pkgs.postfix}/bin/sendmail"

    config :pleroma, Pleroma.User,
      restricted_nicknames: [ "admin", "uninsane", "root" ]

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
    #   password: "{secrets.pleroma.db_password}",

    # Configure web push notifications
    config :web_push_encryption, :vapid_details,
      subject: "mailto:notify.pleroma@uninsane.org"
    #   public_key: "{secrets.pleroma.vapid_public_key}",
    #   private_key: "{secrets.pleroma.vapid_private_key}"

    # config :joken, default_signer: "{secrets.pleroma.joken_default_signer}"
    
    config :pleroma, :database, rum_enabled: false
    config :pleroma, :instance, static_dir: "/var/lib/pleroma/instance/static"
    config :pleroma, Pleroma.Uploaders.Local, uploads: "/var/lib/pleroma/uploads"
    config :pleroma, configurable_from_database: false

    # strip metadata from uploaded images
    config :pleroma, Pleroma.Upload, filters: [Pleroma.Upload.Filter.Exiftool]

    # TODO: GET /api/pleroma/captcha is broken
    config :pleroma, Pleroma.Captcha,
      enabled: false,
      method: Pleroma.Captcha.Native


    # (enabled by colin)
    # Enable Strict-Transport-Security once SSL is working:
    config :pleroma, :http_security,
      sts: true
    
    # docs: https://docs.pleroma.social/backend/configuration/cheatsheet/#logger
    config :logger,
      backends: [{ExSyslogger, :ex_syslogger}]
    
    config :logger, :ex_syslogger,
      level: :warn
    #  level: :debug

    # XXX colin: not sure if this actually _does_ anything
    config :pleroma, :emoji,
      shortcode_globs: ["/emoji/**/*.png"],
      groups: [
        "Cirno": "/emoji/cirno/*.png",
        "Kirby": "/emoji/kirby/*.png",
        "Bun": "/emoji/bun/*.png",
        "Yuru Camp": "/emoji/yuru_camp/*.png",
      ]
    ''
  ];

  systemd.services.pleroma.path = [ 
    # something inside pleroma invokes `sh` w/o specifying it by path, so this is needed to allow pleroma to start
    pkgs.bash 
    # used by Pleroma to strip geo tags from uploads
    pkgs.exiftool 
    # i saw some errors when pleroma was shutting down about it not being able to find `awk`. probably not critical
    pkgs.gawk
    # needed for email operations like password reset
    pkgs.postfix
  ];

  systemd.services.pleroma.serviceConfig = {
    # postgres can be slow to service early requests, preventing pleroma from starting on the first try
    Restart = "on-failure";
  };

  # systemd.services.pleroma.serviceConfig = {
  #   # required for sendmail. see https://git.pleroma.social/pleroma/pleroma/-/issues/2259
  #   NoNewPrivileges = lib.mkForce false;
  #   PrivateTmp = lib.mkForce false;
  #   CapabilityBoundingSet = lib.mkForce "~";
  # };

  sops.secrets.pleroma_secrets = {
    sopsFile = ../../../secrets/servo.yaml;
    owner = config.users.users.pleroma.name;
  };
}
