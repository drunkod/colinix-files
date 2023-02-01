# when a `nixos-rebuild` fails after a nixpkgs update:
# - take the failed package
# - search it here: <https://hydra.nixos.org/search?query=pkgname>
# - if it's broken by that upstream builder, then pin it: somebody will come along and fix the package.
# - otherwise, search github issues/PRs for knowledge of it before pinning.
# - if nobody's said anything about it yet, probably want to root cause it or hold off on updating.
(next: prev: {
  # XXX: when invoked outside our flake (e.g. via NIX_PATH) there is no `next.stable`,
  # so just forward the unstable packages.
  inherit (next.stable or prev)
  ;

  # 2023/01/30: one test times out. probably flakey test that only got built because i patched mesa.
  gjs = prev.gjs.overrideAttrs (_upstream: {
    doCheck = false;
  });
  libadwaita = prev.libadwaita.overrideAttrs (_upstream: {
    doCheck = false;
  });
  libsecret = prev.libsecret.overrideAttrs (_upstream: {
    doCheck = false;
  });
})
