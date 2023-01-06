{ lib, ... }@moduleArgs:

{
  path = import ./path.nix moduleArgs;
  types = import ./types.nix moduleArgs;

  filterNonNull = attrs: lib.filterAttrsRecursive (n: v: v != null) attrs;
  # transform a list into an attrset via a function which maps an element to a name + value
  # Type: mapToAttrs :: (a -> { name, value }) -> [a] -> AttrSet
  mapToAttrs = f: list: builtins.listToAttrs (builtins.map f list);
}
