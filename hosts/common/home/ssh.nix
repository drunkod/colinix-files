{ config, lib, sane-lib, ... }:

with lib;
let
  host = config.networking.hostName;
  user-pubkey = config.sane.ssh.pubkeys."colin@${host}".asUserKey;
  host-keys = filter (k: k.user == "root") (attrValues config.sane.ssh.pubkeys);
  known-hosts-text = concatStringsSep
    "\n"
    (map (k: k.asHostKey) host-keys)
  ;
in
{
  # ssh key is stored in private storage
  sane.persist.home.private = [ ".ssh/id_ed25519" ];
  sane.fs."/home/colin/.ssh/id_ed25519.pub" = sane-lib.fs.wantedText user-pubkey;
  sane.fs."/home/colin/.ssh/known_hosts" = sane-lib.fs.wantedText known-hosts-text;

  users.users.colin.openssh.authorizedKeys.keys =
  let
    user-keys = filter (k: k.user == "colin") (attrValues config.sane.ssh.pubkeys);
  in
    map (k: k.asUserKey) user-keys;
}
