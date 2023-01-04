{ lib, ... }@moduleArgs:

{
  path = import ./path.nix moduleArgs;
  types = import ./types.nix moduleArgs;

  filterNonNull = attrs: lib.filterAttrsRecursive (n: v: v != null) attrs;
}
