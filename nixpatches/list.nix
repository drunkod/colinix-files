{ fetchpatch, fetchurl }: [
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

  # whalebird: 4.6.5 -> 4.7.4
  (fetchpatch {
    # url = "https://git.uninsane.org/colin/nixpkgs/compare/master...pr.whalebird-4.7.4.diff";
    url = "https://git.uninsane.org/colin/nixpkgs/commit/f5c7c70dde720e990fa7e0748d1dc4764d6e4406.diff";
    sha256 = "sha256-L9Ie80loaP6yl5ZFnJ1b5WMDpvO1QFE8tbrW5HBauko=";
  })

  # nixos/mx-puppet-discord: move to matrix category
  (fetchurl {
    url = "https://git.uninsane.org/colin/nixpkgs/commit/87c877fff84717478a96d1b0c65bd2febd350dea.diff";
    sha256 = "sha256-E5TonCj3f8j7kxApBq/suNT5mB7z8uD00NzI34Qh2SE=";
  })

  # signaldctl: init at 0.6.1
  (fetchurl {
    url = "https://git.uninsane.org/colin/nixpkgs/commit/f3c4303231537422267ca32eb97b37f0a9a11d19.diff";
    hash = "sha256-9fIAie0x2VxbHDg9iC8/dxaXIrWi8LzHSoDk9cwAZG0=";
  })

  # phosh-mobile-settings 0.21.1 -> 0.23.1
  (fetchpatch {
    # https://github.com/NixOS/nixpkgs/pull/211877
    url = "https://git.uninsane.org/colin/nixpkgs/commit/352e09d0413ff25139390a6077c7831271d09b8f.diff";
    hash = "sha256-yGsSquIRXapTiWQlLORFTyFEHE5XJfLcM3W/1AJIeL8=";
  })

  # splatmoji: init at 1.2.0
  (fetchpatch {
    # https://github.com/NixOS/nixpkgs/pull/211874
    url = "https://git.uninsane.org/colin/nixpkgs/commit/75149039b6eaf57d8a92164e90aab20eb5d89196.diff";
    hash = "sha256-IvsIcd2wPdz4b/7FMrDrcVlIZjFecCQ9uiL0Umprbx0=";
  })

  ./2022-12-19-i2p-aarch64.patch

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
