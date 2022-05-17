{ pkgs }:

(pkgs.ubootRaspberryPi4_64bit.overrideAttrs (upstream: {
  patches = (upstream.patches or []) ++ [
    # enable booting from > 2 TiB drives
    ./01-enable-large-gpt.patch
  ];
}))

