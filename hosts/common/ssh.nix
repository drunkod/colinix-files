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

    # [{ path :: [String], value :: String }] for the keys we want to install
    globalKeys = sane-lib.flattenAttrs sane-data.keys;
    localKeys = sane-lib.flattenAttrs sane-data.keys.org.uninsane.local;
  in lib.mkMerge (builtins.map
    ({ path, value }: {
      "${keyNameForPath path}" = value;
    })
    (globalKeys ++ localKeys)
  );
}
