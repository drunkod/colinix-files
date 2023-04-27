{ lib
, cargo-docset ? null
, openssl
, pkg-config
, rustPlatform
}:

# docs: <nixpkgs>/doc/languages-frameworks/rust.section.md
rustPlatform.buildRustPackage {
  name = "mx-sanebot";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ] ++ lib.optional (cargo-docset != null) cargo-docset;
  buildInputs = [ openssl ];

  # to build dash/zeal docs:
  # `cargo-docset`
  # `cp -r -rcp target/docset/mx-sanebot.docset ~/.local/share/Zeal/Zeal/docsets/`

  # enables debug builds, if we want: https://github.com/NixOS/nixpkgs/issues/60919.
  hardeningDisable = [ "fortify" ];
}
