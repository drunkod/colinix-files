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
    group = "users";
    extraGroups = [
      "wheel"
      "nixbuild"
      "networkmanager"
      # phosh/mobile. XXX colin: unsure if necessary
      "video"
      "feedbackd"
      "dialout" # required for modem access
    ];
    initialPassword = lib.mkDefault "";
    shell = pkgs.zsh;
    # shell = pkgs.bashInteractive;
    # XXX colin: create ssh key for THIS user by logging in and running:
    #   ssh-keygen -t ed25519
    openssh.authorizedKeys.keys = [
      # TODO: is this key dead?
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSDe/y0e9PSeUwYlMPjzhW0UhNsGAGsW3lCG3apxrD5 colin@colin.desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpmFdNSVPRol5hkbbCivRhyeENzb9HVyf9KutGLP2Zu colin@lappy"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU5GlsSfbaarMvDA20bxpSZGWviEzXGD8gtrIowc1pX colin@desko"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS1qFzKurAdB9blkWomq8gI1g0T3sTs9LsmFOj5VtqX colin@servo"
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

  # affix some UIDs which were historically auto-generated
  # TODO: these vary across machines -- because they're autogenerated.
  #   we should use high-level uids for this.
  users.users.greeter.uid = 999;
  users.users.nm-iodine.uid = 998;
  users.users.sshd.uid = 997;
  users.users.usbmux.uid = 996;

  users.groups.greeter.gid = 999;
  users.groups.polkituser.gid = 998;
  users.groups.sshd.gid = 997;
  users.groups.systemd-coredump.gid = 996;
  users.groups.usbmux.gid = 995;

  # guarantee determinism in uid/gid generation for users:
  assertions = let
    uidAssertions = builtins.attrValues (builtins.mapAttrs (name: user: {
      assertion = user.uid != null;
      message = "non-deterministic user config detected: ${name}";
    }) config.users.users);
    gidAssertions = builtins.attrValues (builtins.mapAttrs (name: group: {
      assertion = group.gid != null;
      message = "non-deterministic group config detected: ${name}";
    }) config.users.groups);
  in uidAssertions ++ gidAssertions;

}
