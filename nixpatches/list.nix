{ fetchpatch, fetchurl }: [
  # librewolf: build with `MOZ_REQUIRE_SIGNING=false`
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/199134.diff";
    # url = "https://git.uninsane.org/colin/nixpkgs/commit/99b82e07fee4d194520d6e8d51bc45c80a4d3c7e.diff";
    sha256 = "sha256-Ne4hyHQDwBHUlWo8Z3QyRdmEv1rYGOjFGxSfOAcLUvQ=";
  })

  # splatmoji: init at 1.2.0
  (fetchpatch {
    # https://github.com/NixOS/nixpkgs/pull/211874
    url = "https://git.uninsane.org/colin/nixpkgs/commit/75149039b6eaf57d8a92164e90aab20eb5d89196.diff";
    hash = "sha256-IvsIcd2wPdz4b/7FMrDrcVlIZjFecCQ9uiL0Umprbx0=";
  })

  # fix handbrake build by: handbrake: 1.5.1 -> 1.6.1
  # PR opened 2023/01/23
  (fetchpatch {
    # see alternate fix: <https://github.com/NixOS/nixpkgs/pull/211834>
    url = "https://github.com/NixOS/nixpkgs/pull/212306.diff";
    hash = "sha256-iQX2NaZaCzZVRlCM0pgXt0gecNwhXGeh3kXEiY38ZIM=";
  })

  ./2022-12-19-i2p-aarch64.patch

  # fix for <https://gitlab.com/signald/signald/-/issues/345>
  # allows to actually run signald
  ./2023-01-25-signald-update.patch

  # fix for CMA memory leak in mesa: <https://gitlab.freedesktop.org/mesa/mesa/-/issues/8198>
  # only necessary on aarch64.
  # it's a revert of nixpkgs commit dcf630c172df2a9ecaa47c77f868211e61ae8e52
  # NB: next nixpkgs update will require changing a line in this patch:
  # - branch  = versions.major version;
  # + branch  = lib.versions.major version;
  ./2023-01-30-mesa-cma-leak.patch

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
