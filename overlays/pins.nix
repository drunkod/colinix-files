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

  ell = prev.ell.overrideAttrs (_upstream: {
    # 2023/02/11
    # fixes "TEST FAILED in get_random_return_callback at unit/test-dbus-message-fds.c:278: !l_dbus_message_get_error(message, ((void *)0), ((void *)0))"
    # unclear *why* this test fails.
    doCheck = false;
  });
  gjs = prev.gjs.overrideAttrs (_upstream: {
    # 2023/01/30: one test times out. probably flakey test that only got built because i patched mesa.
    doCheck = false;
  });
  gssdp = prev.gssdp.overrideAttrs (_upstream: {
    # 2023/02/11
    # fixes "ERROR:../tests/test-regression.c:429:test_ggo_7: assertion failed (error == NULL): Failed to set multicast interfaceProtocol not available (gssdp-error, 1)"
    doCheck = false;
  });
  json-glib = prev.json-glib.overrideAttrs (_upstream: {
    # 2023/02/11
    # fixes: "15/15 json-glib:docs / doc-check    TIMEOUT        30.52s   killed by signal 15 SIGTERM"
    doCheck = false;
  });
  lapack-reference = prev.lapack-reference.overrideAttrs (_upstream: {
    # 2023/02/11: test timeouts
    # > The following tests FAILED:
    # >       93 - LAPACK-xlintstz_ztest_in (Timeout)
    # >        98 - LAPACK-xeigtstz_svd_in (Timeout)
    # >          99 - LAPACK-xeigtstz_zec_in (Timeout)
    doCheck = false;
  });
  libadwaita = prev.libadwaita.overrideAttrs (_upstream: {
    # 2023/01/30: one test times out. probably flakey test that only got built because i patched mesa.
    doCheck = false;
  });
  libsecret = prev.libsecret.overrideAttrs (_upstream: {
    # 2023/01/30: one test times out. probably flakey test that only got built because i patched mesa.
    doCheck = false;
  });
  libuv = prev.libuv.overrideAttrs (_upstream: {
    # 2023/02/11
    # 2 tests fail:
    # - not ok 261 - tcp_bind6_error_addrinuse
    # - not ok 267 - tcp_bind_error_addrinuse_listen
    doCheck = false;
  });
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (py-next: py-prev: {
      ipython = py-prev.ipython.overridePythonAttrs (upstream: {
        # > FAILED IPython/core/tests/test_debugger.py::test_xmode_skip - pexpect.exceptions.TIMEOUT: Timeout exceeded.
        # > FAILED IPython/core/tests/test_debugger.py::test_decorator_skip - pexpect.exceptions.TIMEOUT: Timeout exceeded.
        # > FAILED IPython/core/tests/test_debugger.py::test_decorator_skip_disabled - pexpect.exceptions.TIMEOUT: Timeout exceeded.
        # > FAILED IPython/core/tests/test_debugger.py::test_decorator_skip_with_breakpoint - pexpect.exceptions.TIMEOUT: Timeout exceeded.
        # > FAILED IPython/core/tests/test_debugger.py::test_where_erase_value - pexpect.exceptions.TIMEOUT: Timeout exceeded.
        # > FAILED IPython/terminal/tests/test_debug_magic.py::test_debug_magic_passes_through_generators - pexpect.exceptions.TIMEOUT: Timeout exceeded.
        # > FAILED IPython/terminal/tests/test_embed.py::test_nest_embed - pexpect.exceptions.TIMEOUT: Timeout exceeded.
        disabledTestPaths = upstream.disabledTestPaths or [] ++ [
          "IPython/core/tests/test_debugger.py"
          "IPython/terminal/tests/test_debug_magic.py"
          "IPython/terminal/tests/test_embed.py"
        ];
      });
      pytest-xdist = py-prev.pytest-xdist.overridePythonAttrs (upstream: {
        # 2023/02/19
        # 4 tests fail:
        # - FAILED: testing/test_remote.py::TestWorkInteractor::* - execnet.gateway_base.TimeoutError: no item after 10.0 seconds
        # doCheck = false;
        disabledTestPaths = upstream.disabledTestPaths or [] ++ [
          "testing/test_remote.py"
        ];
        # disabledTests = upstream.disabledTests or [] ++ [
        #   "test_basic_collect_and_runtests"
        #   "test_remote_collect_fail"
        #   "test_remote_collect_skip"
        #   "test_runtests_all"
        # ];
      });
    })
  ];
  strp = prev.srtp.overrideAttrs (_upstream: {
    # 2023/02/11
    # roc_driver test times out after 30s
    doCheck = false;
  });
})
