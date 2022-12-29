{ ... }:
{
  # we can't naively `mount /etc/ssh/host_keys` directly, as all of the `etc` activationScript
  #   (which includes /etc/fstab, and wherein we'd normally insert a nix-store symlink) depends on activationScripts.users.
  # activationScripts.etc depends on users apparently only because it converts names to uids when mapping file permissions.
  # in fact, most everything in /etc/ssh seems to use integer uids -- so we *might* be able to just remove the requirement
  # of etc on users (or duplicate the activation script and run it once before sops).
  #
  # finally (possible best):
  # - TODO: remove the "users" dep on activationScripts.etc, but add a static assertion that all uids/gids are hardcoded (like we do with user gids).
  #
  # alternatively
  # - just tell sops to use the /persist key path (always), and be done with this?
  # - stash symlinks to /nix/persist inside `environment.etc....`, tell sops to use /etc/static/ssh, and add an activationScript that makes `/etc/static` available early?
  # - hack the sops manifest file using during setupSecretsForUsers to use a fully-qualified ssh key pat
  system.activationScripts.persist-ssh-host-keys.text = ''
    mkdir -p /etc/ssh
    ln -sf /nix/persist/etc/ssh/host_keys /etc/ssh/
  '';

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/etc/ssh/host_keys/ssh_host_rsa_key"; }
    { type = "ed25519"; path = "/etc/ssh/host_keys/ssh_host_ed25519_key"; }
  ];
}
