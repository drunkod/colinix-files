{ pkgs }:

(pkgs.systemd.overrideAttrs (upstream: {
  patches = (upstream.patches or []) ++ [
    # give the HDD time to spin down before abruptly cutting power
    ./01-spindown-drive.patch
  ];
}))

