fetchpatch: [
  # for raspberry pi: allow building u-boot for rpi 4{,00}
  # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
  #   (it's a dupe of https://github.com/NixOS/nixpkgs/pull/112677 )
  ./02-rpi4-uboot.patch

  # Fix mk flutter app
  # closed. updates fluffychat 1.2.0 -> 1.6.1, but unstable hashing
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

  # kaiteki: init at 2022-09-03
  (fetchpatch {
    # url = "https://git.uninsane.org/colin/nixpkgs/commit/ca8e17b15e99683e9372b4deb5dd446f1019937d.diff";
    url = "https://github.com/NixOS/nixpkgs/pull/193169.diff";
    sha256 = "sha256-1O9vC/r3jpvGhHGp7d2r3oL7C8kFX2Ph214JV0vWZA0=";
  })

  # phosh: 0.21.0 -> 0.21.1
  (fetchpatch {
    # url = "https://git.uninsane.org/colin/nixpkgs/commit/0b81457690fce39b14c5d3463af0d6331b73b850.diff";
    url = "https://github.com/NixOS/nixpkgs/pull/193700.diff";
    sha256 = "sha256-GtpYSii1c/Kw1NEQ4sVR1nO/kvSa/CSIxuXxL00oBGw=";
  })

  # element-desktop: upgrade electron 19 -> 20
  # merged 2022/10/01
  (fetchpatch {
    # url = "https://git.uninsane.org/colin/nixpkgs/commit/7e6a47b3904f5d8f2a37c35ff2d12772524727a9.diff";
    url = "https://github.com/NixOS/nixpkgs/pull/193799.diff";
    sha256 = "sha256-OcqDIoBcphGZfeeOzaS7Ip1khocpkYrpG6tMGExa3S4=";
  })

  # phosh-mobile-settings: init at 0.21.1
  (fetchpatch {
    # url = "https://git.uninsane.org/colin/nixpkgs/commit/0b197a1fc628e917572f6b0a1a0ce17790bc9a05.diff";
    url = "https://github.com/NixOS/nixpkgs/pull/193845.diff";
    sha256 = "sha256-o3UkY9YoCE9hm1ZQ9a4ItZOksbx57V0iF+qC0077pmo=";
  })

  # fix electrum build: https://github.com/NixOS/nixpkgs/issues/193997
  ./11-electrum-protobuf-fix.patch
]
