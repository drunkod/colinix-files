{ lib
, cargoDocsetHook ? null
, openssl
, pkg-config
, rustPlatform
}:

# docs: <nixpkgs>/doc/languages-frameworks/rust.section.md
rustPlatform.buildRustPackage {
  name = "mx-sanebot";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ] ++ lib.optional (cargoDocsetHook != null) cargoDocsetHook;
  buildInputs = [ openssl ];

  # enables debug builds, if we want: https://github.com/NixOS/nixpkgs/issues/60919.
  hardeningDisable = [ "fortify" ];
}
