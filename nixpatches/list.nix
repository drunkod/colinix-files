{ fakeHash, fetchpatch }: [
  # librewolf: build with `MOZ_REQUIRE_SIGNING=false`
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/199134.diff";
    # url = "https://git.uninsane.org/colin/nixpkgs/commit/99b82e07fee4d194520d6e8d51bc45c80a4d3c7e.diff";
    sha256 = "sha256-Ne4hyHQDwBHUlWo8Z3QyRdmEv1rYGOjFGxSfOAcLUvQ=";
  })

  # trust-dns: init at 0.22.0
  (fetchpatch {
    # https://git.uninsane.org/colin/nixpkgs/compare/master...pr-trust-dns.diff
    url = "https://git.uninsane.org/colin/nixpkgs/commit/feee7e0357a74ab0510b2d113a3bdede1d509759.diff";
    sha256 = "sha256-t4sG+xLDaxbJ/mV5G18N4ag8EC3IXPgtN5FJGANh1Dc=";
  })

  # kiwix-tools: init at 3.4.0
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/206254.diff";
    sha256 = "sha256-Z4V9mOv4HYg3kDnWoYcxz3ch03I/1USrLjzlq4X9YqI=";
  })

  # # kaiteki: init at 2022-09-03
  # vendorHash changes too frequently (might not be reproducible).
  # using local package defn until stabilized
  # (fetchpatch {
  #   url = "https://git.uninsane.org/colin/nixpkgs/commit/e2c7f5f4870fcb0e5405e9001b39a64c516852d4.diff";
  #   # url = "https://github.com/NixOS/nixpkgs/pull/193169.diff";
  #   sha256 = "sha256-UWnfS+stVpUZ3Sfaym9XtVBlwvHWJVMaW7cYIcf3M5Q=";
  # })


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

  # ./07-duplicity-rich-url.patch

  # enable aarch64 support for flutter's dart package
  # ./10-flutter-arm64.patch
]
