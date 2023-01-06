{ lib, ... }@moduleArgs:

{
  fs = import ./fs.nix moduleArgs;
  path = import ./path.nix moduleArgs;
  types = import ./types.nix moduleArgs;

  # if `maybe-null` is non-null, yield that. else, return the `default`.
  withDefault = default: maybe-null: if maybe-null != null then
    maybe-null
  else
    default;

  filterNonNull = attrs: lib.filterAttrsRecursive (n: v: v != null) attrs;
  # transform a list into an attrset via a function which maps an element to a name + value
  # Type: mapToAttrs :: (a -> { name, value }) -> [a] -> AttrSet
  mapToAttrs = f: list: builtins.listToAttrs (builtins.map f list);
}
