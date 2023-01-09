{ lib, ... }@moduleArgs:

rec {
  feeds = import ./feeds.nix moduleArgs;
  fs = import ./fs.nix moduleArgs;
  path = import ./path.nix moduleArgs;
  types = import ./types.nix moduleArgs;

  # if `maybe-null` is non-null, yield that. else, return the `default`.
  withDefault = default: maybe-null: if maybe-null != null then
    maybe-null
  else
    default;

  # removes null entries from the provided AttrSet. acts recursively.
  # Type: filterNonNull :: AttrSet -> AttrSet
  filterNonNull = attrs: lib.filterAttrsRecursive (n: v: v != null) attrs;

  # transform a list into an AttrSet via a function which maps an element to a name + value
  # Type: mapToAttrs :: (a -> { name, value }) -> [a] -> AttrSet
  mapToAttrs = f: list: builtins.listToAttrs (builtins.map f list);

  # flatten a nested AttrSet into a list of { path = [str]; value } items.
  # Type: flattenAttrs :: AttrSet[item|AttrSet] -> [{ path; value; }]
  flattenAttrs = flattenAttrs' [];
  flattenAttrs' = path: value: if builtins.isAttrs value then (
    builtins.concatLists (
      lib.mapAttrsToList
        (name: flattenAttrs' (path ++ [ name ]))
        value
    )
  ) else [
    {
      inherit path value;
    }
  ];
}
