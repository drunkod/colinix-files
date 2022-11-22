{ ... }:
{
  # we wan't an /etc/machine-id which is consistent across boot so that `journalctl` will actually show us
  # logs from previous boots.
  # maybe there's a config option for this (since persistent machine-id is bad for reasons listed in impermanence.nix),
  # but for now generate it from ssh keys.
  system.activationScripts.machine-id = {
    deps = [ "persist-ssh-host-keys" ];
    text = "sha256sum /etc/ssh/host_keys/ssh_host_ed25519_key | cut -c 1-32 > /etc/machine-id";
  };
}
