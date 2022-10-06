{ pkgs }:

(pkgs.matrix-appservice-discord.overrideAttrs (upstream: {
  # 2022-10-05: the service can't login as an ordinary user unless i change the source
  doCheck = false;
  patches = (upstream.patches or []) ++ [
    # bind to an IP address which is usable behind a netns
    ./01-puppet.patch
  ];
}))

