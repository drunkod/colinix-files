# disable tests for packages which flake.
# tests will fail for a variety of reasons:
# - they were coded with timeouts that aren't reliable under heavy load.
# - they assume a particular architecture (e.g. x86) whereas i compile on multiple archs.
# - they assume too much about their environment and fail under qemu.
#
(next: prev:
let
  dontCheck = p: p.overrideAttrs (_: {
    doCheck = false;
  });
in {
  # 2023/07/27
  # 4 tests fail when building `host-pkgs.moby.emulated.elfutils`
  # it might be enough to only disable checks when targeting aarch64, which could reduce rebuilds?
  elfutils = dontCheck prev.elfutils;

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (py-next: py-prev: {
      pyarrow = py-prev.pyarrow.overridePythonAttrs (upstream: {
        # 2023/04/02
        # disabledTests = upstream.disabledTests ++ [ "test_generic_options" ];
        disabledTestPaths = upstream.disabledTestPaths or [] ++ [
          "pyarrow/tests/test_flight.py"
        ];
      });
    })
  ];

  # 2023/02/22
  # "27/37 tracker:core / service                          TIMEOUT         60.37s   killed by signal 15 SIGTERM"
  tracker = dontCheck prev.tracker;
})
