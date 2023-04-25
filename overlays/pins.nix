# when a `nixos-rebuild` fails after a nixpkgs update:
# - take the failed package
# - search it here: <https://hydra.nixos.org/search?query=pkgname>
# - if it's broken by that upstream builder, then pin it: somebody will come along and fix the package.
# - otherwise, search github issues/PRs for knowledge of it before pinning.
# - if nobody's said anything about it yet, probably want to root cause it or hold off on updating.
#
# note that these pins apply to *all* platforms:
# - natively compiled packages
# - cross compiled packages
# - qemu-emulated packages

(next: prev: {
  # XXX: when invoked outside our flake (e.g. via NIX_PATH) there is no `next.stable`,
  # so just forward the unstable packages.
  inherit (next.stable or prev)
  ;
  # chromium can take 4 hours to build from source, with no signs of progress.
  # disable it if you're in a rush.
  # chromium = next.emptyDirectory;

  # TODO(2023/04/24): remove this. it's upstreamed for next staging-next `nix flake update`
  sway-unwrapped = prev.sway-unwrapped.overrideAttrs (upstream: {
    patches = upstream.patches or [] ++ [
      (next.fetchpatch {
        name = "LIBINPUT_CONFIG_ACCEL_PROFILE_CUSTOM.patch";
        url = "https://github.com/swaywm/sway/commit/dee032d0a0ecd958c902b88302dc59703d703c7f.diff";
        hash = "sha256-dx+7MpEiAkxTBnJcsT3/1BO8rYRfNLecXmpAvhqGMD0=";
      })
    ];
  });
})
