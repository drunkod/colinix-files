{ config, lib, ... }:
{
  environment.etc."ssh/host_keys".source = "/nix/persist/etc/ssh/host_keys";

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/etc/ssh/host_keys/ssh_host_rsa_key"; }
    { type = "ed25519"; path = "/etc/ssh/host_keys/ssh_host_ed25519_key"; }
  ];

}
