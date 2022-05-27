{ config, pkgs, lib, ... }:

# installer docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
{
  # Users are exactly these specified here;
  # old ones will be deleted (from /etc/passwd, etc) upon upgrade.
  users.mutableUsers = false;

  # docs: https://nixpkgs-manual-sphinx-markedown-example.netlify.app/generated/options-db.xml.html#users-users
  users.users.colin = {
    # sets group to "users" (?)
    isNormalUser = true;
    home = "/home/colin";
    uid = 1000;
    # XXX colin: this is what the installer has, but is it necessary?
    # group = "users";
    extraGroups = [ "wheel" "nixbuild" "networkmanager" ];
    initialPassword = lib.mkDefault "";
    shell = pkgs.zsh;
    # shell = pkgs.bashInteractive;
    # XXX colin: create ssh key for THIS user by logging in and running:
    #   ssh-keygen -t ed25519
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSDe/y0e9PSeUwYlMPjzhW0UhNsGAGsW3lCG3apxrD5 colin@colin.desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+MZ/l5d8g5hbxMB9ed1uyvhV85jwNrSVNVxb5ujQjw colin@lappy"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU5GlsSfbaarMvDA20bxpSZGWviEzXGD8gtrIowc1pX colin@desko"
      # TODO: should probably only let this authenticate to my server
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGCLCA9KbjXaXNNMJJvqbPO5KQQ64JCdG8sg88AfdKzi colin@moby"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # TODO colin: move this somewhere else!
  programs.vim.defaultEditor = true;
}
