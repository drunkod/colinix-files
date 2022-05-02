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
    extraGroups = [ "wheel" ];
    initialHashedPassword = "";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSDe/y0e9PSeUwYlMPjzhW0UhNsGAGsW3lCG3apxrD5 colin@colin.desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+MZ/l5d8g5hbxMB9ed1uyvhV85jwNrSVNVxb5ujQjw colin@colin.laptop"
    ];
    packages = [
      pkgs.gnumake
      pkgs.dig
      pkgs.duplicity
      pkgs.fd
      pkgs.file
      pkgs.git
      pkgs.htop
      pkgs.iftop
      pkgs.iotop
      pkgs.iptables
      pkgs.lsof
      pkgs.matrix-synapse
      pkgs.mix2nix
      pkgs.netcat
      pkgs.nettools
      pkgs.nmap
      pkgs.ripgrep
      pkgs.telnet
      pkgs.sudo
      pkgs.wireguard
      pkgs.zola
      (pkgs.vim_configurable.customize {
        name = "vim";
        vimrcConfig.customRC = ''
          " wtf vim project: NOBODY LIKES MOUSE FOR VISUAL MODE
          set mouse-=a
          " copy/paste to system clipboard
          set clipboard=unnamedplus
          " <tab> completion menu settings
          set wildmenu
          set wildmode=longest,list,full
          " highlight all matching searches (using / and ?)
          set hlsearch
          " allow backspace to delete empty lines in insert mode
          set backspace=indent,eol,start
          " highlight trailing space & related syntax errors (does this work?)
          let c_space_errors=1
          let python_space_errors=1
        '';
      })
    ];
  };

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "colin";

  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  programs.vim.defaultEditor = true;

  # gitea doesn't create the git user
  users.users.git = {
    description = "Gitea Service";
    home = "/var/lib/gitea";
    useDefaultShell = true;
    group = "gitea";
    isSystemUser = true;
  };
}
