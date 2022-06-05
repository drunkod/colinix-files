{ lib
, fetchFromGitHub
, flutter
, olm
, imagemagick
, makeDesktopItem
}:

flutter.mkFlutterApp rec {
  pname = "kaiteki";
  version = "1.1";

  vendorHash = "sha256-N7s63e8z4pAFtFV9cFN+CIIg+A/s8lYfiJWrBkMkkd0=";

  src = fetchFromGitHub {
    owner = "Kaiteki-Fedi";
    repo = "Kaiteki";
    rev = "0a322313071e4391949d23d9b006d74de65f58d9";
    hash = "sha256-ggDIbVwueS162m15TFaC6Tcg+0lpcVGi4x/O691sxR8";
  };

  desktopItem = makeDesktopItem {
    name = "Kaiteki";
    exec = "@out@/bin/kaiteki";
    icon = "kaiteki";
    desktopName = "Kaiteki";
    genericName = "Micro-blogging client";
    categories = [ "Network" "InstantMessaging" "GTK" ];
  };

  sourceRoot = "source/src/kaiteki";

  # postUnpack = ''
  #   mv assets assets-toplevel
  #   mv src/kaiteki/* .
  # '';

  buildInputs = [
    olm
  ];

  nativeBuildInputs = [
    imagemagick
  ];

  # flutterExtraFetchCommands = ''
  #   M=$(echo $TMP/.pub-cache/hosted/pub.dartlang.org/matrix-*)
  #   sed -i $M/scripts/prepare.sh \
  #     -e "s|/usr/lib/x86_64-linux-gnu/libolm.so.3|/bin/sh|g"  \
  #     -e "s|if which flutter >/dev/null; then|exit; if which flutter >/dev/null; then|g"

  #   pushd $M
  #   bash scripts/prepare.sh
  #   popd
  # '';

  # replace olm dummy path
  # postConfigure = ''
  #   M=$(echo $depsFolder/.pub-cache/hosted/pub.dartlang.org/matrix-*)
  #   ln -sf ${olm}/lib/libolm.so.3 $M/ffi/olm/libolm.so
  # '';

  # postInstall = ''
  #   FAV=$out/app/data/flutter_assets/assets/favicon.png
  #   ICO=$out/share/icons

  #   install -D $FAV $ICO/fluffychat.png
  #   mkdir $out/share/applications
  #   cp $desktopItem/share/applications/*.desktop $out/share/applications

  #   for s in 24 32 42 64 128 256 512; do
  #     D=$ICO/hicolor/''${s}x''${s}/apps
  #     mkdir -p $D
  #     convert $FAV -resize ''${s}x''${s} $D/fluffychat.png
  #   done

  #   substituteInPlace $out/share/applications/*.desktop \
  #     --subst-var out
  # '';

  meta = with lib; {
    description = "The comfy Fediverse client";
    homepage = "https://craftplacer.moe/projects/kaiteki/";
    license = licenses.agpl3Plus;
    # maintainers = with maintainers; [ uninsane ];
    platforms = platforms.linux;
  };
}
