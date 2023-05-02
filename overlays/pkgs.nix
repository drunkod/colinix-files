(next: prev:
  let
    additional = import ../pkgs/additional next;
    python-packages = {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: import ../pkgs/python-packages { inherit (py-prev) callPackage; })
      ];
    };

    # to avoid infinite recursion, the patched packages require *unpatched* inputs,
    # but we don't want to just send `prev` naively, else patched packages might
    # take dependencies on unpatched versions of other packages we patch; or they
    # won't be able to use inputs from `additional`, etc.
    #
    # so, call the patched packages using the `next` package set, except with
    # they packages we're "about to" patch replaced with their versions from `prev`.
    #
    # we could alternatively pass `pkgs = prev // { inherit (next) callPackage; }`,
    patched = import ../pkgs/patched (next // patchedInputs);
    patchedInputs = builtins.mapAttrs (name: _patched: prev."${name}") patched;

    sane = additional // python-packages // patched;
  in sane // { inherit sane; }
)
