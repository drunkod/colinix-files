# Nix User Repository (NUR)
# - <https://github.com/nix-community/NUR>
#
# this file is not reachable from the top-level of my nixos configs (i.e. toplevel flake.nix)
# nor is it intended for anyone who wants to reference my config directly
#   (consider the toplevel flake.nix outputs instead).
#
# rather, this is the entrypoint through which NUR finds my packages, modules, overlays.
# it's reachable only from those using this repo via NUR.
#
# to manually query available packages, modules, etc, try:
# - nix eval --impure --expr 'builtins.attrNames (import ./. {})'

{ pkgs ? import <nixpkgs> {} }:
let
  sanePkgs = import ../../pkgs { inherit pkgs; };
in
({
  overlays.pkgs = import ../../overlays/pkgs.nix;
  pkgs = sanePkgs;

  modules = import ../../modules { inherit (pkgs) lib; };
  lib = import ../../modules/lib { inherit (pkgs) lib; };
} // sanePkgs)
