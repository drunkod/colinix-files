{ pkgs }:

(pkgs.matrix-appservice-discord.overrideAttrs (upstream: {
  # 2022-10-05: the service can't login as an ordinary user unless i change the source
  doCheck = false;
  patches = (upstream.patches or []) ++ [
    # don't register with better-discord as a bot
    ./01-puppet.patch
    # don't ask Discord admin for approval before bridging
    ./02-auto-approve.patch
  ];
}))

