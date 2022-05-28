{
  ddns-he.password = "<REPLACEME>";

  # format: b2://$key_id:$app_key@$bucket
  # create key with: b2 create-key --bucket uninsane-host-duplicity uninsane-host-duplicity-safe listBuckets,listFiles,readBuckets,readFiles,writeFiles
  #   ^ run this until you get a key with no forward slashes :upside_down:
  #   web-created keys are allowed to delete files, which you probably don't want for an incremental backup program
  duplicity.url = "b2://<REPLACEME:KEY_ID>:<REPLACEME:APPKEY>:<REPLACEME:BUCKET>";
  # remote backups will be encrypted using this (gpg) passphrase
  duplicity.passphrase = "<REPLACEME>";

  # to generate:
  # wg genkey > wg0.private
  # wg pubkey < wg0.private > wg0.public
  wireguard.privateKey = "<REPLACEME>";

  # these would otherwise be found in 'pleroma.secret.exs'
  pleroma.secret_key_base = "<REPLACEME>";
  pleroma.signing_salt = "<REPLACEME>";
  pleroma.db_password = "<REPLACEME>";
  pleroma.vapid_public_key = "<REPLACEME>";
  pleroma.vapid_private_key = "<REPLACEME>";
  pleroma.joken_default_signer = "<REPLACEME>";

  # keep this synchronized with the dovecot auth
  matrix-synapse.smtp_pass = "<REPLACEME>";

  # passwd file looks like /etc/passwd.
  # use nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "my passwd" to generate the password
  dovecot.hashedPasswd.colin = "<REPLACEME>";
  dovecot.hashedPasswd.matrix-synapse = "<REPLACEME>";

  # generate with nix-store --generate-binary-cache-key nixcache.uninsane.org cache-priv-key.pem cache-pub-key.pem
  nix-serve.cache-priv-key = "<REPLACEME>";
} // import ./local.nix
