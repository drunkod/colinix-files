(next: prev:
  let
    additional = import ../pkgs/additional
      { pkgs = next; lib = prev.lib; };
    python-packages = {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: import ../pkgs/python-packages { inherit (py-prev) callPackage; })
      ];
    };

    patched = import ../pkgs/patched
      { pkgs = next; lib = prev.lib; unpatched = prev; };

    sane = additional // python-packages // patched;
  in sane // {
    sane = next.recurseIntoAttrs sane;
  }
)
