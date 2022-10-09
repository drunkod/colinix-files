fetchpatch: [
  # Flutter: 3.0.4 -> 3.3.3, flutter.dart: 2.17.5 -> 2.18.2
  # merged 2022/10/07
  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/189338.diff";
  #   sha256 = "sha256-HRkOIBcOnSXyTKkYxnMgZou8MHU/5eNhxxARdUq9UWg=";
  #   # url = "https://git.uninsane.org/colin/nixpkgs/commit/889c3a8cbc91c0d10b34ab7825fa1f6d1d31668a.diff";
  #   # sha256 = "sha256-qVWLpNoW3HVSWRtXS1BcSusKOq0CAMfY0BVU9MxPm98=";
  # })
  #
  # XXX this is a cherry-pick of all the commits in PR 189338 (as appears in tree).
  # the diff yielded by Github is apparently not the same somehow (maybe because the branches being merged had diverged too much?)
  ./11-flutter-3.3.3-189338.patch

  # phosh-mobile-settings: init at 0.21.1
  (fetchpatch {
    url = "http://git.uninsane.org/colin/nixpkgs/commit/0c1a7e8504291eb0076bbee3f8ebf693f4641112.diff";
    # url = "https://github.com/NixOS/nixpkgs/pull/193845.diff";
    sha256 = "sha256-OczjlQcG7sTM/V9Y9VL/qdwaWPKfjAJsh3czqqhRQig=";
  })

  # kaiteki: init at 2022-09-03
  (fetchpatch {
    url = "https://git.uninsane.org/colin/nixpkgs/commit/e2c7f5f4870fcb0e5405e9001b39a64c516852d4.diff";
    # url = "https://github.com/NixOS/nixpkgs/pull/193169.diff";
    sha256 = "sha256-UWnfS+stVpUZ3Sfaym9XtVBlwvHWJVMaW7cYIcf3M5Q=";
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
  ./12-flutter-arm64-2.patch
]
