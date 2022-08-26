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
  # alternative to https://github.com/NixOS/nixpkgs/pull/173200
  ./04-dart-2.7.0.patch
  # whalebird: support aarch64
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/176476.diff";
    sha256 = "sha256-126DljM06hqPZ3fjLZ3LBZR64nFbeTfzSazEu72d4y8=";
  })

  # TODO: upstream
  ./07-duplicity-rich-url.patch
  # TODO: upstream
  ./08-zecwallet-lite.patch
  # upstream PR: https://github.com/NixOS/nixpkgs/pull/188342
  ./09-makemkv-1.17.1.patch
]
