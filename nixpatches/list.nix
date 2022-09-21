fetchpatch: [
  # for raspberry pi: allow building u-boot for rpi 4{,00}
  # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
  #   (it's a dupe of https://github.com/NixOS/nixpkgs/pull/112677 )
  ./02-rpi4-uboot.patch

  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/186839.diff";
  #   sha256 = "sha256-NdIfie+eTy4V1vgqiiRPtWdnxZ5ZHsvCMfkEDUv9SC8=";
  # })
  ./11-186839-fluffychat1.2.0-1.6.1.patch

  # # # Flutter: 3.0.4->3.3.2, flutter.dart: 2.17.5->2.18.1
  # # (fetchpatch {
  # #   url = "https://github.com/NixOS/nixpkgs/pull/189338.diff";
  # #   sha256 = "sha256-MppSk1D3qQT8Z4lzEZ93UexoidT8yqM7ASPec4VvxCI=";
  # # })
  # enable aarch64 support for flutter's dart package
  # ./10-flutter-arm64.patch


  # TODO: upstream
  ./07-duplicity-rich-url.patch

]
