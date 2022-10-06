{ pkgs }:

(pkgs.matrix-appservice-discord.overrideAttrs (upstream: {
  # 2022-10-05: the service can't login as an ordinary user unless i change the source
  doCheck = false;
  patches = (upstream.patches or []) ++ [
    # don't register with better-discord as a bot
    ./01-puppet.patch
    # don't ask Discord admin for approval before bridging
    ./02-auto-approve.patch
    # disable Matrix -> Discord edits because they do not fit Discord semantics
    ./03-no-edits.patch
    # we don't want to notify Discord users that a Matrix user was kicked/banned
    ./04-no-kickbans.patch
    # don't notify Discord users when the Matrix room changes (name, topic, membership)
    ./05-no-meta.patch
  ];
}))

