fetchpatch: [
  # for raspberry pi: allow building u-boot for rpi 4{,00}
  # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
  #   (it's a dupe of https://github.com/NixOS/nixpkgs/pull/112677 )
  ./02-rpi4-uboot.patch

  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/186839.diff";
    sha256 = "sha256-NdIfie+eTy4V1vgqiiRPtWdnxZ5ZHsvCMfkEDUv9SC8=";
  })

  # # # Flutter: 3.0.4->3.3.2, flutter.dart: 2.17.5->2.18.1
  # # (fetchpatch {
  # #   url = "https://github.com/NixOS/nixpkgs/pull/189338.diff";
  # #   sha256 = "sha256-MppSk1D3qQT8Z4lzEZ93UexoidT8yqM7ASPec4VvxCI=";
  # # })
  # enable aarch64 support for flutter's dart package
  ./10-flutter-arm64.patch


  # TODO: upstream
  ./07-duplicity-rich-url.patch

  # navidrome: adhoc hack to fix the build
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/191467.diff";
    sha256 = "sha256-Np0J06RER/0GGUhL/PDuVjpYYIPzB9A3EPWwTWpS/D4=";
  })

  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/192472.diff";
  #   sha256 = "sha256-J4Vp2yErNZkKqZbpLY4mMo9n0Qtai1mAh6kZ8DOV4v4=";
  # })
  # (fetchpatch {
  #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/192472.diff";
  #   sha256 = "sha256-J5Vp2yErNZkKqZbpLY4mMo9n0Qtai1mAh6kZ8DOV4v4=";
  # })

  ./192472-pleroma-no-strip-debug.patch
]
