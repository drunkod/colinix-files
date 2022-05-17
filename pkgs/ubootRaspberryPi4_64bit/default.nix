{ pkgs }:

(pkgs.ubootRaspberryPi4_64bit.overrideAttrs (upstream: {
  patches = (upstream.patches or []) ++ [
    # enable booting from > 2 TiB drives
    ./01-skip-lba-check.patch
    # enable some builtin commands to aid in debugging, while we're here
    ./02-extra-cmds.patch
    # ./03-verbose-log.patch
  ];
}))

