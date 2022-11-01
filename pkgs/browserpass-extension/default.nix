{ stdenv
, fetchFromGitHub
, gnused
, jq
, mkYarnModules
, zip
}:

let
  pname = "browserpass-extension";
  version = "3.7.2";
  src = fetchFromGitHub {
    owner = "browserpass";
    repo = "browserpass-extension";
    rev = version;
    sha256 = "sha256-uDJ0ID8mD+5WLQK40+OfzRNIOOhZWsLYIi6QgcdIDvc=";
  };
  browserpass-extension-yarn-modules = mkYarnModules {
    inherit pname version;
    packageJSON = "${src}/src/package.json";
    yarnLock = "${src}/src/yarn.lock";
  };
  extid = "browserpass@maximbaz.com";
in stdenv.mkDerivation {
  inherit pname version src;

  patchPhase = ''
    # dependencies are built separately: skip the yarn install
    ${gnused}/bin/sed -i /yarn\ install/d src/Makefile
  '';

  preBuild = ''
    ln -s ${browserpass-extension-yarn-modules}/node_modules src/node_modules
  '';

  installPhase = ''
    BASE=$out/share/mozilla/extensions/\{ec8030f7-c20a-464f-9b0e-13a3a9e97384\}
    mkdir -p $BASE

    pushd firefox

    # firefox requires addons to have an id field when sideloading:
    # - <https://extensionworkshop.com/documentation/publish/distribute-sideloading/>
    cat manifest.json \
      | ${jq}/bin/jq '. + { applications: {gecko: {id: "${extid}" }}, browser_specific_settings: {gecko: {id: "${extid}"}} }' \
      > manifest.patched.json
    mv manifest{.patched,}.json

    ${zip}/bin/zip -r $BASE/browserpass@maximbaz.com.xpi ./*

    popd
  '';

  passthru = {
    inherit extid;
  };
}
