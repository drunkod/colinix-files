{
  description = "Sane matrix chatbot";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib; eachSystem allSystems (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      nativeBuildInputs = with pkgs; [
        pkg-config
      ];
      buildInputs = with pkgs; [
        openssl
      ];
    in rec {
      packages = {
        # docs: <nixpkgs>/doc/languages-frameworks/rust.section.md
        mx-sanebot = pkgs.rustPlatform.buildRustPackage {
          name = "mx-sanebot";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          # enables debug builds, if we want: https://github.com/NixOS/nixpkgs/issues/60919.
          hardeningDisable = [ "fortify" ];
          inherit buildInputs nativeBuildInputs;
        };
      };
      defaultPackage = packages.mx-sanebot;

      devShells.default = with pkgs; mkShell {
        # enables debug builds, if we want: https://github.com/NixOS/nixpkgs/issues/60919.
        hardeningDisable = [ "fortify" ];

        # Allow cargo to download crates.
        SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

        inherit buildInputs;
        nativeBuildInputs = [ cargo ] ++ nativeBuildInputs;
      };
    });
}
