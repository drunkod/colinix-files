{ lib, ... }@moduleArgs:

rec {
  feeds = import ./feeds.nix moduleArgs;
  fs = import ./fs.nix moduleArgs;
  path = import ./path.nix moduleArgs;
  types = import ./types.nix moduleArgs;

  # like `builtins.listToAttrs` but any duplicated `name` throws error on access.
  # Type: listToDisjointAttrs :: [{ name :: String, value :: Any }] -> AttrSet
  listToDisjointAttrs = l: lib.foldl' lib.attrsets.unionOfDisjoint {} (builtins.map nameValueToAttrs l);

  # evaluate a `{ name, value }` pair in the same way that `listToAttrs` does.
  # Type: nameValueToAttrs :: { name :: String, value :: Any } -> Any
  nameValueToAttrs = { name, value }: {
    "${name}" = value;
  };

  # if `maybe-null` is non-null, yield that. else, return the `default`.
  withDefault = default: maybe-null: if maybe-null != null then
    maybe-null
  else
    default;

  # removes null entries from the provided AttrSet. acts recursively.
  # Type: filterNonNull :: AttrSet -> AttrSet
  filterNonNull = attrs: lib.filterAttrsRecursive (n: v: v != null) attrs;

  # return only the subset of `attrs` whose name is in the provided set.
  # Type: filterByName :: [String] -> AttrSet
  filterByName = names: attrs: lib.filterAttrs
    (name: value: builtins.elem name names)
    attrs;

  # transform a list into an AttrSet via a function which maps an element to a { name, value } pair.
  # it's an error for the same name to be specified more than once
  # Type: mapToAttrs :: (a -> { name :: String, value :: Any }) -> [a] -> AttrSet
  mapToAttrs = f: list: listToDisjointAttrs (builtins.map f list);

  # flatten a nested AttrSet into a list of { path = [String]; value } items.
  # Type: flattenAttrs :: AttrSet[AttrSet|Any] -> [{ path :: String, value :: Any }]
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
