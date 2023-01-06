{ config, lib, pkgs, ... }:

let
  host = config.networking.hostName;
  user_pubkey = (import ../pubkeys.nix).users."${host}";
  known_hosts_text = builtins.concatStringsSep
    "\n"
    (builtins.attrValues (import ../pubkeys.nix).hosts);
  mkSymlink = text: {
    symlink.text = text;
    wantedBeforeBy = [ "multi-user.target" ];
  };
in lib.mkIf config.sane.home-manager.enable {
  # ssh key is stored in private storage
  sane.persist.home.private = [ ".ssh/id_ed25519" ];
  sane.fs."/home/colin/.ssh/id_ed25519.pub" = mkSymlink user_pubkey;

  home-manager.users.colin = {
    programs.ssh.enable = true;
    # this optionally accepts multiple known_hosts paths, separated by space.
    programs.ssh.userKnownHostsFile = builtins.toString (pkgs.writeText "known_hosts" known_hosts_text);
  };
}
