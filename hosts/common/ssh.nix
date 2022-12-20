{ ... }:
{
  # we can't naively `mount /etc/ssh/host_keys` directly,
  # as /etc/fstab may not be populated yet (since that file depends on e.g. activationScripts.users)
  # we can't even depend on impermanence's `createPersistentStorageDirs` to create the source/target directories
  # since that also depends on `users`.
  # previously we manually `mount --bind` the host_keys here, but it's difficult to make that idempotent.
  # symlinking seems to work just as well, and is easier to make idempotent
  system.activationScripts.persist-ssh-host-keys.text = ''
    mkdir -p /etc/ssh
    ln -sf /nix/persist/etc/ssh/host_keys /etc/ssh/
  '';

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/etc/ssh/host_keys/ssh_host_rsa_key"; }
    { type = "ed25519"; path = "/etc/ssh/host_keys/ssh_host_ed25519_key"; }
  ];
}
