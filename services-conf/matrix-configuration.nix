# docs: https://nixos.wiki/wiki/Matrix
# docs: https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
{ config, pkgs, lib, ... }:

{
  services.matrix-synapse.enable = true;
  services.matrix-synapse.server_name = "uninsane.org";

  # services.matrix-synapse.enable_registration_captcha = true;
  # services.matrix-synapse.enable_registration_without_verification = true;
  services.matrix-synapse.enable_registration = true;
  # services.matrix-synapse.registration_shared_secret = "<shared key goes here>";

  # default for listeners is port = 8448, tls = true, x_forwarded = false.
  # we change this because the server is situated behind nginx.
  services.matrix-synapse.listeners = [
    {
      port = 8008;
      bind_address = "127.0.0.1";
      type = "http";
      tls = false;
      x_forwarded = true;
      resources = [
        {
          names = [ "client" "federation" ];
          compress = false;
        }
      ];
    }
  ];

  services.matrix-synapse.extraConfig = ''
    registration_requires_token: true
  '';

  # new users may be registered on the CLI:
  # register_new_matrix_user -c /nix/store/8n6kcka37jhmi4qpd2r03aj71pkyh21s-homeserver.yaml http://localhost:8008
}
