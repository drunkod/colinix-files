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

  # zecwallet: 1.7.13 -> 1.8.8
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/193276.diff";
    sha256 = "sha256-tgwX/Tb1jQIcao8nTVJt4Y20iiHIeu+g8vCb5OOMIyQ=";
  })

  # whalebird: 4.6.0 -> 4.6.5
  (fetchpatch {
    url = "https://git.uninsane.org/colin/nixpkgs/commit/5f410db5e0bc24521ad413c33285a3175517941c.diff";
    sha256 = "sha256-222ZhU3l9fUTeqJvkk/1MhIMzzPaxthZpThYHi3rjV8=";
  })
]
