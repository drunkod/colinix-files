fetchpatch: [
  # phosh-mobile-settings: init at 0.21.1
  (fetchpatch {
    url = "http://git.uninsane.org/colin/nixpkgs/commit/0c1a7e8504291eb0076bbee3f8ebf693f4641112.diff";
    # url = "https://github.com/NixOS/nixpkgs/pull/193845.diff";
    sha256 = "sha256-OczjlQcG7sTM/V9Y9VL/qdwaWPKfjAJsh3czqqhRQig=";
  })

  # # kaiteki: init at 2022-09-03
  # vendorHash changes too frequently (might not be reproducible).
  # using local package defn until stabilized
  # (fetchpatch {
  #   url = "https://git.uninsane.org/colin/nixpkgs/commit/e2c7f5f4870fcb0e5405e9001b39a64c516852d4.diff";
  #   # url = "https://github.com/NixOS/nixpkgs/pull/193169.diff";
  #   sha256 = "sha256-UWnfS+stVpUZ3Sfaym9XtVBlwvHWJVMaW7cYIcf3M5Q=";
  # })

  # freshrss: patchShebangs instead of specifying interpreter in the service
  (fetchpatch {
    url = "https://git.uninsane.org/colin/nixpkgs/commit/9443d83e6fee728c1926a783647b45011bd3b514.diff";
    sha256 = "sha256-Lngle5YTE7ymQyUarKbebMjiaTlY5cJBoaeZk7AgbXE=";
  })

  # nautilus: look for the gtk4 FileChooser settings instead of the gtk4 one
  (fetchpatch {
    url = "https://git.uninsane.org/colin/nixpkgs/commit/4636a04c1c4982a0e71ae77d3aa6f52d1a3170f1.diff";
    sha256 = "sha256-XKfXStdcveYuk58rlORVJOv0a9Q5aRj1bYT5k79rL0g=";
  })

  # Fix mk flutter app
  # closed (not merged). updates fluffychat 1.2.0 -> 1.6.1, but unstable hashing
  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/186839.diff";
  #   sha256 = "sha256-NdIfie+eTy4V1vgqiiRPtWdnxZ5ZHsvCMfkEDUv9SC8=";
  # })

  # for raspberry pi: allow building u-boot for rpi 4{,00}
  # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
  #   (it's a dupe of https://github.com/NixOS/nixpkgs/pull/112677 )
  ./02-rpi4-uboot.patch

  # TODO: upstream
  ./07-duplicity-rich-url.patch

  # enable aarch64 support for flutter's dart package
  # ./10-flutter-arm64.patch
]
