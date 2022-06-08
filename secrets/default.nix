{
  # these would otherwise be found in 'pleroma.secret.exs'
  pleroma.secret_key_base = "<REPLACEME>";
  pleroma.signing_salt = "<REPLACEME>";
  pleroma.db_password = "<REPLACEME>";
  pleroma.vapid_public_key = "<REPLACEME>";
  pleroma.vapid_private_key = "<REPLACEME>";
  pleroma.joken_default_signer = "<REPLACEME>";

  # keep this synchronized with the dovecot auth
  matrix-synapse.smtp_pass = "<REPLACEME>";
} // import ./local.nix
