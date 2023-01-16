{ ... }:
{
  services.signald.enable = true;

  # TODO: required?
  # comes from <nix-matrix-appservices:examples/mautrix.nix>
  systemd.services.matrix-as-signal = {
    requires = [ "signald.service" ];
    after = [ "signald.service" ];
    unitConfig = {
      JoinsNamespaceOf = "signald.service";
    };
    path = [
      pkgs.ffmpeg # voice messages need `ffmpeg`
    ];
  };


  services.matrix-appservices.services.signal = {
    port = 29184;
    format = "mautrix-python";
    package = pkgs.mautrix-signal;
    serviceConfig = {
      StateDirectory = [ "matrix-as-signal" "signald" ];
      SupplementaryGroups = [ "signald" ];
    };
    settings.signal = {
      socket_path = config.services.signald.socketPath;
      outgoing_attachment_dir = "/var/lib/signald/tmp";
    };
  };
}
