{ config, lib, pkgs, ... }:

lib.mkIf config.sane.home-manager.enable
{
  home-manager.users.colin = let
    host = config.networking.hostName;
    user_pubkey = (import ../pubkeys.nix).users."${host}";
    known_hosts_text = builtins.concatStringsSep
      "\n"
      (builtins.attrValues (import ../pubkeys.nix).hosts);
  in { config, ...}: {
    # ssh key is stored in private storage
    home.file.".ssh/id_ed25519".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/private/.ssh/id_ed25519";
    home.file.".ssh/id_ed25519.pub".text = user_pubkey;

    programs.ssh.enable = true;
    # this optionally accepts multiple known_hosts paths, separated by space.
    programs.ssh.userKnownHostsFile = builtins.toString (pkgs.writeText "known_hosts" known_hosts_text);
  };
}
