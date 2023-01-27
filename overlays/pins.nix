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
    # broken on 2023/01/14 via mtxclient dep, aarch64-only:
    # fixed on 2023/01/24?
    #   error: builder for '/nix/store/gwidl0c9ksxjgx0dgwnjssix4ikq73v5-mtxclient-0.9.0.drv' failed with exit code 2;
    #      last 10 log lines:
    #      > make[2]: *** [CMakeFiles/matrix_client.dir/build.make:370: CMakeFiles/matrix_client.dir/lib/structs/events/encrypted.cpp.o] Error 1
    #      > In file included from /build/source/include/mtxclient/crypto/client.hpp:17,
    #      >                  from /build/source/lib/crypto/utils.cpp:17:
    #      > /build/source/include/mtx/identifiers.hpp:12:10: fatal error: compare: No such file or directory
    #      >    12 | #include <compare>
    #      >       |          ^~~~~~~~~
    #      > compilation terminated.
    #      > make[2]: *** [CMakeFiles/matrix_client.dir/build.make:132: CMakeFiles/matrix_client.dir/lib/crypto/utils.cpp.o] Error 1
    #      > make[1]: *** [CMakeFiles/Makefile2:83: CMakeFiles/matrix_client.dir/all] Error 2
    #      > make: *** [Makefile:136: all] Error 2
    #      For full logs, run 'nix log /nix/store/gwidl0c9ksxjgx0dgwnjssix4ikq73v5-mtxclient-0.9.0.drv'.
    #   error: 1 dependencies of derivation '/nix/store/4i2d1qdh4x6n23h1jbcbhm8q9q2hch9a-nheko-0.11.0.drv' failed to build
    #   error: 1 dependencies of derivation '/nix/store/k4f7k7cvjp8rb7clhlfq3yxgs6lbfmk7-home-manager-path.drv' failed to build
    #   error: 1 dependencies of derivation '/nix/store/67d9k554188lh4ddl4ar6j74mpc3r4sv-home-manager-generation.drv' failed to build
    #   error: 1 dependencies of derivation '/nix/store/5qjxzhsw1jvh2d7jypbcam9409ivb472-user-environment.drv' failed to build
    #   error: 1 dependencies of derivation '/nix/store/hrb3qpdbisqh0lzlyz1g9g4164khmqwn-etc.drv' failed to build
    #   error: 1 dependencies of derivation '/nix/store/ny21xyicbgim5wy7ksg2hibd9gn7i01b-nixos-system-moby-23.05pre-git.drv' failed to build
    # nheko
  ;
})
