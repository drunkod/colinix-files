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
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "";
    # shell = pkgs.bashInteractive;
    # XXX colin: create ssh key for THIS user by logging in and running:
    #   ssh-keygen -t ed25519
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSDe/y0e9PSeUwYlMPjzhW0UhNsGAGsW3lCG3apxrD5 colin@colin.desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+MZ/l5d8g5hbxMB9ed1uyvhV85jwNrSVNVxb5ujQjw colin@colin.laptop"
    ];
  };

  # automatically log in at the virtual consoles.
  # using root here makes sure we always have an escape hatch
  # services.getty.autologinUser = "root";

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  programs.vim.defaultEditor = true;

  # gitea doesn't create the git user
  # users.users.git = {
  #   description = "Gitea Service";
  #   home = "/var/lib/gitea";
  #   useDefaultShell = true;
  #   group = "gitea";
  #   isSystemUser = true;
  #   # sendmail access (not 100% sure if this is necessary)
  #   extraGroups = [ "postdrop" ];
  # };

  # # this is required to allow pleroma to send email.
  # # raw `sendmail` works, but i think pleroma's passing it some funny flags or something, idk.
  # # hack to fix that.
  # users.users.pleroma.extraGroups = [ "postdrop" ];
}
