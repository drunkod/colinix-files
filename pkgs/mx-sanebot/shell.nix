{ pkgs ? import <nixpkgs> {} }:

let
  mx-sanebot = pkgs.callPackage ./. { };
in
  pkgs.mkShell {
    nativeBuildInputs = mx-sanebot.buildInputs ++ mx-sanebot.nativeBuildInputs ++ [
      pkgs.cargo
    ];

    # Allow cargo to download crates.
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  }
