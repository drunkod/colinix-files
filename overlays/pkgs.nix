(next: prev:
  let
    toplevel-pkgs = import ../pkgs
      { pkgs = next; lib = prev.lib; unpatched = prev; };
    python-packages = {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: import ../pkgs/python-packages { inherit (py-prev) callPackage; })
      ];
    };
  in
    # expose all my packages into the root scope:
    # - `additional` packages
    # - `patched` versions of nixpkgs (which necessarily shadow their nixpkgs version)
    # - `pythonPackagesExtensions`
    toplevel-pkgs
)
