{ lib, utils, ... }:

rec {
  path = {
    # split the string path into a list of string components.
    # root directory "/" becomes the empty list [].
    # implicitly performs normalization so that:
    # split "a//b/" => ["a" "b"]
    # split "/a/b" =>  ["a" "b"]
    split = str: builtins.filter (seg: (builtins.isString seg) && seg != "" ) (builtins.split "/" str);
    # return a string path, with leading slash but no trailing slash
    joinAbs = comps: "/" + (builtins.concatStringsSep "/" comps);
    concat = paths: path.joinAbs (builtins.concatLists (builtins.map path.split paths));
    # normalize the given path
    norm = str: path.joinAbs (path.split str);
    # return the parent directory. doesn't care about leading/trailing slashes.
    # the parent of "/" is "/".
    parent = str: path.norm (builtins.dirOf (path.norm str));
    hasParent = str: (path.parent str) != (path.norm str);
  };
}
