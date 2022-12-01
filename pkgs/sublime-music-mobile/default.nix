{ pkgs
, lib
, libhandy
, ... }:

(pkgs.sublime-music.overrideAttrs (upstream: {
  src = pkgs.fetchFromGitLab {
    owner = "BenjaminSchaaf";
    repo = "sublime-music";
    rev = "4ce2f222f13020574d54110d90839f48d8689b9d";
    sha256 = "sha256-V6YyBbPKAfZb5FVOesNcC6TfJbO73WZ4DvlOSWSSZzU=";
  };

  buildInputs = upstream.buildInputs ++ [
    # TODO: need to patch handy to include the pulltab thing
    libhandy
  ];

  # i think Benjamin didn't update the tests?
  doCheck = false;
  doInstallCheck = false;

  meta.description = "A mobile-friendly sublime music fork";
}))
