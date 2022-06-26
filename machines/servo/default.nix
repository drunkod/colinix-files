{ pkgs, ... }:

{
  imports = [
    ./fs.nix
    ./hardware.nix
    ./net.nix
    ./users.nix
    ./services/ddns-he.nix
    ./services/gitea.nix
    ./services/ipfs.nix
    ./services/jackett.nix
    ./services/jellyfin.nix
    ./services/matrix.nix
    ./services/nginx.nix
    ./services/nix-serve.nix
    ./services/pleroma.nix
    ./services/postfix.nix
    ./services/postgres.nix
    ./services/transmission.nix
  ];

  colinsane.home-manager.enable = true;
  colinsane.home-manager.extraPackages = [
    pkgs.matrix-synapse
  ];
  colinsane.services.duplicity.enable = true;

  sops.secrets.duplicity_passphrase = {
    sopsFile = ../../secrets/servo.yaml;
  };

  # both transmission and ipfs try to set different net defaults.
  # we just use the most aggressive of the two here:
  boot.kernel.sysctl = {
    "net.core.rmem_max" = "4194304";  # 4MB
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

