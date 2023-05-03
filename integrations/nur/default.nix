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
# to manually query available packages, modules, etc, true:
# - nix eval --impure --expr 'builtins.attrNames (import ./. {})'

{ pkgs ? import <nixpkgs> {} }:
let
  sanePkgs = import ../../pkgs/additional pkgs;
in
({
  # contains both packages not in nixpkgs, and patched versions of those in nixpkgs
  overlays.pkgs = import ../../overlays/pkgs.nix;
  # contains only my packages which aren't in nixpkgs
  pkgs = sanePkgs;

  modules = import ../../modules { inherit (pkgs) lib; };
  lib = import ../../modules/lib { inherit (pkgs) lib; };
} // sanePkgs)
