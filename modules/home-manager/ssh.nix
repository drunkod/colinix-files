{ config, lib, pkgs, sane-lib, ... }:

with lib;
let
  host = config.networking.hostName;
  user-pubkey = config.sane.ssh.pubkeys."colin@${host}".asUserKey;
  host-keys = filter (k: k.user == "root") (attrValues config.sane.ssh.pubkeys);
  known-hosts-text = concatStringsSep
    "\n"
    (map (k: k.asHostKey) host-keys)
  ;
in lib.mkIf config.sane.home-manager.enable {
  # ssh key is stored in private storage
  sane.persist.home.private = [ ".ssh/id_ed25519" ];
  sane.fs."/home/colin/.ssh/id_ed25519.pub" = sane-lib.fs.wantedText user-pubkey;

  home-manager.users.colin = {
    programs.ssh.enable = true;
    # this optionally accepts multiple known_hosts paths, separated by space.
    programs.ssh.userKnownHostsFile = toString (pkgs.writeText "known_hosts" known-hosts-text);
  };
}
