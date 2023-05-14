{ ... }:

{
  sops.secrets."ddns_afraid" = {
    sopsFile = ../../../secrets/servo/ddns_afraid.env.bin;
  };
  sops.secrets."ddns_he" = {
    sopsFile = ../../../secrets/servo/ddns_he.env.bin;
  };

  sops.secrets."dovecot_passwd" = {
    sopsFile = ../../../secrets/servo/dovecot_passwd.bin;
  };

  sops.secrets."duplicity_passphrase" = {
    sopsFile = ../../../secrets/servo/duplicity_passphrase.env.bin;
  };

  sops.secrets."freshrss_passwd" = {
    sopsFile = ../../../secrets/servo/freshrss_passwd.bin;
  };

  sops.secrets."matrix_synapse_secrets" = {
    sopsFile = ../../../secrets/servo.yaml;
  };
  sops.secrets."mautrix_signal_env" = {
    sopsFile = ../../../secrets/servo/mautrix_signal_env.bin;
    format = "binary";
  };

  sops.secrets."mediawiki_pw" = {
    sopsFile = ../../../secrets/servo/mediawiki_pw.bin;
    format = "binary";
  };

  sops.secrets."nix_serve_privkey" = {
    sopsFile = ../../../secrets/servo/nix_serve_privkey.bin;
  };

  sops.secrets."pleroma_secrets" = {
    sopsFile = ../../../secrets/servo/pleroma_secrets.bin;
  };

  sops.secrets."wg_ovpns_privkey" = {
    sopsFile = ../../../secrets/servo/wg_ovpns_privkey.bin;
  };
}
