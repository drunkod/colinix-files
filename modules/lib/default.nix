{ ... }@moduleArgs:

{
  path = import ./path.nix moduleArgs;
  types = import ./types.nix moduleArgs;
}
