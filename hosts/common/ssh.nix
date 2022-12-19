{ ... }:
{
  # we place the host keys (which we want to be persisted) into their own directory so that we can
  # bind mount that whole directory instead of doing it per-file.
  # otherwise, this is identical to nixos defaults
  sane.impermanence.service-dirs = [ "/etc/ssh/host_keys" ];

  # we can't naively `mount /etc/ssh/host_keys` directly,
  # as /etc/fstab may not be populated yet (since that file depends on e.g. activationScripts.users)
  # we can't even depend on impermanence's `createPersistentStorageDirs` to create the source/target directories
  # since that also depends on `users`.
  system.activationScripts.persist-ssh-host-keys.text = ''
    mkdir -p /etc/ssh/host_keys
    if ! (mountpoint /etc/ssh/host_keys)
    then
      # avoid mounting the keys more than once, otherwise we have a million _stacked_ entries.
      # TODO: should we just symlink? or find a way to make sure the existing mount is correct.
      mount --bind /nix/persist/etc/ssh/host_keys /etc/ssh/host_keys
    fi
  '';

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/etc/ssh/host_keys/ssh_host_rsa_key"; }
    { type = "ed25519"; path = "/etc/ssh/host_keys/ssh_host_ed25519_key"; }
  ];
}
