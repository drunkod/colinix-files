{ pkgs }:

(pkgs.jackett.overrideAttrs (upstream: {
  patches = [
    # bind to an IP address which is usable behind a netns
    ./01-fix-bind-host.patch
  ];
}))

