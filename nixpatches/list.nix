fetchpatch: [
  # phosh: allow fractional scaling
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/175872.diff";
    sha256 = "sha256-mEmqhe8DqlyCxkFWQKQZu+2duz69nOkTANh9TcjEOdY=";
  })
  # for raspberry pi: allow building u-boot for rpi 4{,00}
  # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
  ./02-rpi4-uboot.patch
  # alternative to https://github.com/NixOS/nixpkgs/pull/173200
  ./04-dart-2.7.0.patch
  # whalebird: support aarch64
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/176476.diff";
    sha256 = "sha256-126DljM06hqPZ3fjLZ3LBZR64nFbeTfzSazEu72d4y8=";
  })

  # jackett updates
  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/169395.diff";
  #   sha256 = "sha256-JZh/5I22ZALnzaWQXAbvOJ1ZVjuRpPNY5WWFJDalzXk=";
  # })
  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/182847.diff";
  #   sha256 = "sha256-EojqEVNBIyM4DJYLMiY+UKey8RV4tuIv0uyTMEhKiRo=";
  # })

  # discord updates
  # (fetchpatch {
  #   # "fix desktop icon location": required only so subsequent patches apply
  #   url = "https://github.com/NixOS/nixpkgs/pull/171002.diff";
  #   sha256 = "sha256-7JauhPBqEXoml6ppzwABAWNq8AcmV6Gso7LV4QQVRBI=";
  # })
  # (fetchpatch {
  #   # "add openasar option"
  #   url = "https://github.com/NixOS/nixpkgs/pull/178507.diff";
  #   sha256 = "sha256-X+ql7NyhP7ksFRHSQ/NKS6gFdAP5d1jL8WRYX4tbuhI=";
  # })
  # if using the above Discord patches, need apply 179906 to get xdg-open to work again

  # TODO: upstream
  ./07-duplicity-rich-url.patch
  # TODO: upstream
  ./08-zecwallet-lite.patch
]
