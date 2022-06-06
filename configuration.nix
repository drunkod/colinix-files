# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# USEFUL COMMANDS:
#   nix show-config
#   nix eval --raw <expr>  => print an expression. e.g. nixpkgs.raspberrypifw prints store path to the package
#   nix-option   ##  query options -- including their SET VALUE; similar to search: https://search.nixos.org/options
#   nixos-rebuild switch --upgrade   ## pull changes from the nixos channel (e.g. security updates) and rebuild

{ config, pkgs, ... }:

{

  # enable flake support.
  # the real config root lives in flake.nix
  nix = {
    #package = pkgs.nixFlakes;
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # SOPS configuration:
  #   docs: https://github.com/Mic92/sops-nix
  #
  # for each new user you want to edit sops files:
  # create a private age key from ssh key:
  #   $ mkdir -p ~/.config/sops/age; ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt; chmod 600 ~/.config/sops/age/keys.txt
  #   if the private key was password protected, then first decrypt it:
  #     $ cp ~/.ssh/id_ed25519 /tmp/id_ed25519
  #     $ ssh-keygen -p -N "" -f /tmp/id_ed25519
  #
  # for each user you want to decrypt secrets:
  #   $ cat ~/.ssh/id_ed25519.pub | ssh-to-age
  #   add the result to .sops.yaml
  #   since we specify ssh pubkeys in the nix config, you can just grep for `ssh-ed25519` here and use those instead
  #
  # for each machine you want to decrypt secrets:
  #   $ cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
  #   add the result to .sops.yaml
  #   $ sops updatekeys secrets/example.yaml
  #
  # to create a new secret:
  #   $ sops secrets/example.yaml
  #   control access below (sops.secret.<x>.owner = ...)
  #
  # to read a secret:
  #   $ cat /run/secrets/example_key

  # sops.age.sshKeyPaths = [ "/home/colin/.ssh/id_ed25519_dec" ];
  # This will add secrets.yml to the nix store
  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
  sops.defaultSopsFile = ./secrets/example.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    # "/home/colin/.ssh/id_ed25519_dec"
  ];
  # This is using an age key that is expected to already be in the filesystem
  # sops.age.keyFile = "/home/colin/.ssh/age.pub";
  # sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  # This will generate a new key if the key specified above does not exist
  # sops.age.generateKey = true;
  # This is the actual specification of the secrets.
  sops.secrets.example_key = {
    owner = config.users.users.colin.name;
  };
  # sops.secrets."myservice/my_subdir/my_secret" = {};
}

