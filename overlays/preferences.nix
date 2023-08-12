# personal preferences
# prefer to encode these in `sane.programs`
# resort to this method for e.g. system dependencies, or things which are referenced from too many places.
(next: prev: {
  pipewire = prev.pipewire.override {
    # avoid a dep on python3.10-PyQt5, which has mixed qt5 versions.
    # this means we lose firewire support (oh well..?)
    ffadoSupport = false;
  };

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pySelf: pySuper: {
      # TODO(2023/08/02): cryptography (a dependency of komikku -> keyring -> secretstorage -> cryptography) doesn't cross compile
      # so disable it. can be re-enabled in next staging -> master merge.
      # see:
      # - <https://github.com/NixOS/nixpkgs/pull/245287/files>
      # - <https://github.com/NixOS/nixpkgs/pull/244135>
      keyring = (pySuper.keyring.override {
        secretstorage = null;
        jeepney = null;
        # separate from `cryptography`: jaraco-classes doesn't cross compile
        # but it looks like `keyring` has some _temporary_ fallback logic for
        # when jaraco-classes isn't installed (i.e. may break in future).
        jaraco-classes = null;
      }).overrideAttrs (upstream: {
        postPatch = (upstream.postPatch or "") + ''
          sed -i /SecretStorage/d setup.cfg
          sed -i /jeepney/d setup.cfg
          sed -i /jaraco.classes/d setup.cfg
        '';
      });
    })
  ];
})
