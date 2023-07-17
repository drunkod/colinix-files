{ stdenv
, callPackage
, fetchFirefoxAddon
, gnused
, jq
, strip-nondeterminism
, unzip
, writeScript
, zip
}:
let
  # given an addon, repackage it without some `perm`ission
  removePermission = perm: addon: mkPatchedAddon addon {
    patchPhase = ''
      NEW_MANIFEST=$(jq 'del(.permissions[] | select(. == "${perm}"))' manifest.json)
      echo "$NEW_MANIFEST" > manifest.json
    '';
    nativeBuildInputs = [ jq ];
  };

  mkPatchedAddon = addon: args:
  let
    extid = addon.passthru.extid;
    # merge our requirements into the derivation args
    args' = args // {
      passthru = {
        inherit extid;
        original = addon;
      } // (args.passthru or {});
      nativeBuildInputs = [
        strip-nondeterminism
        unzip
        zip
      ] ++ (args.nativeBuildInputs or []);
    };
  in stdenv.mkDerivation ({
    # heavily borrows from <repo:nixos/nixpkgs:pkgs/build-support/fetchfirefoxaddon/default.nix>
    inherit (addon) name;
    unpackPhase = ''
      UUID="${extid}"
      echo "patching firefox addon $name into $out/$UUID.xpi"

      # extract the XPI into the working directory
      unzip -q "${addon}/$UUID.xpi" -d "."
    '';

    installPhase = ''
      runHook preInstall

      # repackage the XPI
      mkdir "$out"
      zip -r -q -FS "$out/$UUID.xpi" ./*
      strip-nondeterminism "$out/$UUID.xpi"

      runHook postInstall
    '';
  } // args');
  # given an addon, add a `passthru.withoutPermission` method for further configuration
  mkConfigurable = pkg: pkg.overrideAttrs (final: upstream: {
    passthru = (upstream.passthru or {}) // {
      withoutPermission = perm: mkConfigurable (removePermission perm final.finalPackage);
    };
  });

  addon = name: extid: hash: mkConfigurable (fetchFirefoxAddon {
    inherit name hash;
    url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
    # extid can be found by unar'ing the above xpi, and copying browser_specific_settings.gecko.id field
    fixedExtid = extid;
  });
  localAddon = pkg: mkConfigurable (fetchFirefoxAddon {
    inherit (pkg) name;
    src = "${pkg}/share/mozilla/extensions/\\{ec8030f7-c20a-464f-9b0e-13a3a9e97384\\}/${pkg.extid}.xpi";
    fixedExtid = pkg.extid;
  });
in {
  # get names from:
  # - ~/ref/nix-community/nur-combined/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
  # `wget ...xpi`; `unar ...xpi`; `cat */manifest.json | jq '.browser_specific_settings.gecko.id'`
  #
  # TODO: give these updateScript's

  browserpass-extension = localAddon (callPackage ./browserpass-extension { });

  # TODO: build bypass-paywalls from source? it's mysteriously disappeared from the Mozilla store.
  # bypass-paywalls-clean.package = addon "bypass-paywalls-clean" "{d133e097-46d9-4ecc-9903-fa6a722a6e0e}" "sha256-oUwdqdAwV3DezaTtOMx7A/s4lzIws+t2f08mwk+324k=";
  # bypass-paywalls-clean.enable = lib.mkDefault true;

  # TODO: give these update scripts, make them reachable via `pkgs`
  ether-metamask = addon "ether-metamask" "webextension@metamask.io" "sha256-UI83wUUc33OlQYX+olgujeppoo2D2PAUJ+Wma5mH2O0=";
  i2p-in-private-browsing = addon "i2p-in-private-browsing" "i2ppb@eyedeekay.github.io" "sha256-dJcJ3jxeAeAkRvhODeIVrCflvX+S4E0wT/PyYzQBQWs=";
  sidebery = addon "sidebery" "{3c078156-979c-498b-8990-85f7987dd929}" "sha256-YONfK/rIjlsrTgRHIt3km07Q7KnpIW89Z9r92ZSCc6w=";
  sponsorblock = mkPatchedAddon
    (addon "sponsorblock" "sponsorBlocker@ajay.app" "sha256-b/OTFmhSEUZ/CYrYCE4rHVMQmY+Y78k8jSGMoR8vsZA=")
    {
      patchPhase = ''
        # patch sponsorblock to not show the help tab on first launch.
        # XXX: i tried to build sponsorblock from source and patch this *before* it gets webpack'd,
        # but web shit is absolutely cursed and building from source requires a fucking PhD
        # (if you have one, feel free to share your nix package)
        ${gnused}/bin/sed -i 's/default\.config\.userID)/default.config.userID && false)/' js/background.js
      '';
    };
  ublacklist = addon "ublacklist" "@ublacklist" "sha256-NZ2FmgJiYnH7j2Lkn0wOembxaEphmUuUk0Ytmb0rNWo=";
  ublock-origin = addon "ublock-origin" "uBlock0@raymondhill.net" "sha256-EGGAA+cLUow/F5luNzFG055rFfd3rEyh8hTaL/23pbM=";
}
