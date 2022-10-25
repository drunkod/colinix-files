{ ... }:
{
  # we place the host keys (which we want to be persisted) into their own directory to ease that.
  # otherwise, this is identical to nixos defaults
  sane.impermanence.service-dirs = [ "/etc/ssh/host_keys" ];

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/etc/ssh/host_keys/ssh_host_rsa_key"; }
    { type = "ed25519"; path = "/etc/ssh/host_keys/ssh_host_ed25519_key"; }
  ];
}
