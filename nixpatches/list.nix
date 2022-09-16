fetchpatch: [
  # phosh: allow fractional scaling
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/175872.diff";
    sha256 = "sha256-mEmqhe8DqlyCxkFWQKQZu+2duz69nOkTANh9TcjEOdY=";
  })

  # for raspberry pi: allow building u-boot for rpi 4{,00}
  # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
  #   (it's a dupe of https://github.com/NixOS/nixpkgs/pull/112677 )
  ./02-rpi4-uboot.patch

  # TODO: more patches are required prior to this one
  # flutter.dart: 2.16.1 -> 2.16.2
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/172873.diff";
    sha256 = "sha256-HGYk83XOhFe1wWNCKNdF6s/7laWJ0Jisb8bDJcHVlsQ=";
  })
  # Flutter: 2.10.1->3.0.4
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/173200.diff";
    sha256 = "sha256-g1tZdLTrAJx3ijgabqz8XInC20PQM3FYRENQ7c6NfQw=";
  })
  # dart: 2.17.3 -> 2.18.0
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/189841.diff";
    sha256 = "sha256-E3rTNex7PiFHsLgtb0x9/Q/naqDYD1vFuGyduV4Z6qY=";
  })
  # enable aarch64 support for flutter's dart package
  ./10-flutter-arm64.patch
  # Flutter: 3.0.4->3.3.2, flutter.dart: 2.17.5->2.18.1
  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/189338.diff";
  #   sha256 = "sha256-MppSk1D3qQT8Z4lzEZ93UexoidT8yqM7ASPec4VvxCI=";
  # })


  # whalebird: support aarch64
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/176476.diff";
    sha256 = "sha256-126DljM06hqPZ3fjLZ3LBZR64nFbeTfzSazEu72d4y8=";
  })

  # TODO: upstream
  ./07-duplicity-rich-url.patch

  # zecwallet-lite: init at 1.7.13
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/180960.diff";
    sha256 = "sha256-HVVj/T3yQtjYBoxXpoPiG9Zar/eik9IoDVDhTOehBdY=";
  })

  # makemkv: 1.16.7 -> 1.17.1
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/188342.diff";
    sha256 = "sha256-3M4DpvXf5Us70FX5geE0L1Ns23Iw2NG82YNlwSd+WzI=";
  })
]
