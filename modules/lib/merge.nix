{ lib, sane-lib, ... }:

rec {
  # like `mkMerge`, but tries to do normal attribute merging by default and only creates `mkMerge`
  # entries at the highest point where paths overlap between items.
  mergeTopLevel = l:
    if builtins.length l == 0 then
      lib.mkMerge []
    else if builtins.length l == 1 then
      lib.head l
    else if builtins.all isAttrsNotMerge l then
      # merge each toplevel attribute
      lib.zipAttrsWith (_name: mergeTopLevel) l
    else
      lib.mkMerge l;

  # tests that `i` is a normal attrs, and not something make with `lib.mkMerge`.
  isAttrsNotMerge = i: builtins.isAttrs i && i._type or "" != "merge";


  # type-checked `lib.mkMerge`, intended to be usable at the top of a file.
  # `take` is a function which defines a spec enforced against every item to be merged.
  # for example:
  #   take = f: { x = f.x; y.z = f.y.z; };
  # - the output is guaranteed to have an `x` attribute and a `y.z` attribute and nothing else.
  # - each output is a `lib.mkMerge` of the corresponding paths across the input lists.
  # - if an item in the input list defines an attr not captured by `f`, this function will throw.
  #
  # Type: mkTypedMerge :: (Attrs -> Attrs) -> [Attrs] -> Attrs
  mkTypedMerge = take: l:
    let
      pathsToMerge = findTerminalPaths take [];
      merged = builtins.map (p: lib.setAttrByPath p (mergeAtPath p l)) pathsToMerge;
    in
      assert builtins.all (i: assertTakesEveryAttr take i []) l;
      sane-lib.joinAttrsets merged;

  # `take` is as in mkTypedMerge. this function queries which items `take` is interested in.
  # for example:
  #   take = f: { x = f.x; y.z = f.y.z; };
  # - for `path == []` we return the toplevel attr names: [ "x" "y"]
  # - for `path == [ "y" ]` we return [ "z" ]
  # - for `path == [ "x" ]` or `path == [ "y" "z" ]` we return []
  #
  # Type: findSubNames :: (Attrs -> Attrs) -> [String] -> [String]
  findSubNames = take: path:
    let
      # define the current path, but nothing more.
      curLevel = lib.setAttrByPath path {};
      # `take` will either set:
      # - { $path = path }  => { $path = {} };
      # - { $path.next = path.next }  => { $path = { next = ?; } }
      # so, index $path into the output of `take`,
      # and if it has any attrs that means we're interested in those too.
      nextLevel = lib.getAttrFromPath path (take curLevel);
    in
      builtins.attrNames nextLevel;

  # computes a list of all terminal paths that `take` is interested in,
  # where each path is a list of attr names to descend to reach that terminal.
  # Type: findTerminalPaths :: (Attrs -> Attrs) -> [String] -> [[String]]
  findTerminalPaths = take: path:
    let
      subNames = findSubNames take path;
    in if subNames == [] then
      [ path ]
    else
      let
        terminalsPerChild = builtins.map (name: findTerminalPaths take (path ++ [name])) subNames;
      in
        lib.concatLists terminalsPerChild;

  # merges all present values for the provided path
  # Type: mergeAtPath :: [String] -> [Attrs] -> (lib.mkMerge)
  mergeAtPath = path: l:
    let
      itemsToMerge = builtins.filter (lib.hasAttrByPath path) l;
    in lib.mkMerge (builtins.map (lib.getAttrFromPath path) itemsToMerge);

  # throw if `item` includes any data not wanted by `take`.
  # this is recursive: `path` tracks the current location being checked.
  assertTakesEveryAttr = take: item: path:
    let
      takesSubNames = findSubNames take path;
      itemSubNames = findSubNames (_: item) path;
      unexpectedNames = lib.subtractLists takesSubNames itemSubNames;
      takesEverySubAttr = builtins.all (name: assertTakesEveryAttr take item (path ++ [name])) itemSubNames;
    in
      if takesSubNames == [] then
        # this happens when the user takes this whole subtree: i.e. *all* subnames are accepted.
        true
      else if unexpectedNames != [] then
        let
          p = lib.concatStringsSep "." (path ++ lib.sublist 0 1 unexpectedNames);
        in
          throw ''unexpected entry: ${p}''
      else
        takesEverySubAttr;
}
