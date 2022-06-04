{ lib, stdenv, fetchurl, autoPatchelfHook, makeDesktopItem, makeWrapper, electron
, nodePackages, alsa-lib, gtk3, libdbusmenu, libxshmfence, mesa, nss }:

let
  desktopItem = makeDesktopItem {
    desktopName = "Whalebird";
    genericName = "An Electron based Mastodon client for Windows, Mac and Linux";
    categories = [ "Network" ];
    exec = "opt/Whalebird/whalebird";
    icon = "whalebird";
    name = "whalebird";
  };
in
stdenv.mkDerivation rec {
  pname = "whalebird";
  version = "4.6.0";

  src = let
    downloads = "https://github.com/h3poteto/whalebird-desktop/releases/download/${version}";
  in
    {
      x86_64-linux = fetchurl {
        url = downloads + "/Whalebird-${version}-linux-x64.tar.bz2";
        sha256 = "02f2f4b7184494926ef58523174acfa23738d5f27b4956d094836a485047c2f8";
      };
      aarch64-linux = fetchurl {
        url = downloads + "/Whalebird-${version}-linux-arm64.tar.bz2";
        sha256 = "de0cdf7cbd6f0305100a2440e2559ddce0a5e4ad73a341874d6774e23dc76974";
      };
    }.${stdenv.system};

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    nodePackages.asar
  ];

  buildInputs = [ alsa-lib gtk3 libdbusmenu libxshmfence mesa nss ];

  dontConfigure = true;

  unpackPhase = ''
    mkdir -p ./opt
    tar -xf ${src} -C ./opt
    # remove the version/target suffix from the untar'd directory
    mv ./opt/Whalebird-* ./opt/Whalebird
  '';

  buildPhase = ''
    runHook preBuild

    # Necessary steps to find the tray icon
    asar extract opt/Whalebird/resources/app.asar "$TMP/work"
    substituteInPlace $TMP/work/dist/electron/main.js \
      --replace "jo,\"tray_icon.png\"" "\"$out/opt/Whalebird/resources/build/icons/tray_icon.png\""
    asar pack --unpack='{*.node,*.ftz,rect-overlay}' "$TMP/work" opt/Whalebird/resources/app.asar

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    mv opt $out

    # install icon/desktop files
    mkdir -p "$out/share/icons/hicolor/256x256/apps"
    cp "$out/opt/Whalebird/resources/build/icons/256x256.png" "$out/share/icons/hicolor/256x256/apps/whalebird.png"
    mkdir -p "$out/share/applications"
    cp "${desktopItem}/share/applications/whalebird.desktop" "$out/share/applications/whalebird.desktop"

    makeWrapper ${electron}/bin/electron $out/bin/whalebird \
      --add-flags $out/opt/Whalebird/resources/app.asar

    runHook postInstall
  '';

  meta = with lib; {
    description = "Electron based Mastodon, Pleroma and Misskey client for Windows, Mac and Linux";
    homepage = "https://whalebird.social";
    license = licenses.mit;
    maintainers = with maintainers; [ wolfangaukang ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
