{ config, ... }:
{
  home-manager.users.colin = let
    host = config.networking.hostName;
  in { config, ...}: {
    # ssh key is stored in private storage
    home.file.".ssh/id_ed25519".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/private/.ssh/id_ed25519";
    home.file.".ssh/id_ed25519.pub".text = (import ../pubkeys.nix).users."${host}";
    # alternatively: use `programs.ssh.userKnownHostsFile`
    home.file.".ssh/known_hosts".text = builtins.concatStringsSep
      "\n"
      (builtins.attrValues (import ../pubkeys.nix).hosts);
  };
}
