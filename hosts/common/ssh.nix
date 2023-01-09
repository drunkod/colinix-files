{ config, lib, sane-data, sane-lib, ... }:

{
  sane.ssh.pubkeys =
  let
    # path is a DNS-style path like [ "org" "uninsane" "root" ]
    keyNameForPath = path:
      let
        rev = lib.reverseList path;
        name = builtins.head rev;
        host = lib.concatStringsSep "." (builtins.tail rev);
      in
      "${name}@${host}";

    # given a DNS-style recursive AttrSet, return a flat AttrSet that maps ssh id => pubkey.
    keysFor = attrs:
      let
        by-path = sane-lib.flattenAttrs attrs;
      in
        sane-lib.mapToAttrs ({ path, value }: {
          name = keyNameForPath path;
          inherit value;
        }) by-path;
    globalKeys = keysFor sane-data.keys;
    localKeys = keysFor sane-data.keys.org.uninsane.local;
  in lib.mkMerge [ globalKeys localKeys ];
}
