# Cargo.nix and crate-hashes.json were created with:
# - `nix run '.#crate2nix' -- generate -f https://gitlab.gnome.org/GNOME/fractal`
# - `sed -i 's/target."curve25519_dalek_backend"/target."curve25519_dalek_backend" or ""/g' Cargo.nix`
# - in Cargo.nix change the fractal source from `src = ../../../../../ref/repos/gnome/fractal to
# src = pkgs.fetchFromGitLab {
#   domain = "gitlab.gnome.org";
#   owner = "GNOME";
#   repo = "fractal";
#   rev = "350a65cb0a221c70fc3e4746898036a345ab9ed8";
#   hash = "sha256-z6uURqMG5pT8rXZCv5IzTjXxtt/f4KUeCDSgk90aWdo=";
# };

{ pkgs }:
let
  cargoNix = import ./Cargo.nix {
    inherit pkgs;
    release = false;
  };
in
  cargoNix.workspaceMembers.fractal.build
