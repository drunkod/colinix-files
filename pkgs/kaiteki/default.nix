{ lib
, fetchFromGitHub
, flutter
, makeDesktopItem
, imagemagick
, xdg-user-dirs
}:

flutter.mkFlutterApp rec {
  pname = "kaiteki";
  version = "unstable-2022-09-03";

  # this hash seems unstable -- depends on other nixpkgs, perhaps?
  vendorHash = "sha256-+kVwa5FObRYOdkPrF7jd0qOB+wwBm+OvdJP8NdSXTJ8=";

  src = fetchFromGitHub {
    owner = "Kaiteki-Fedi";
    repo = "Kaiteki";
    # rev = "cf94ec55063cd7af20a37103fc40c588a634962f";
    # hash = "sha256-jtRT0Q4/i3dxRYcC6HPClL9Iw1PizkIUgswU1eusKig=";
    # this is the last hash before the code uses features not apparently supported by our version of dart.
    rev = "fd1e26c98f37ad6a98ed549da879c91721f997d0";
    hash = "sha256-N7n6o/B9s0DCYf9HFMZSCPShpE65wKl9FaQ5dbFnr1E=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ imagemagick ];

  desktopItem = makeDesktopItem {
    name = "Kaiteki";
    exec = "@out@/bin/kaiteki";
    icon = "kaiteki";
    desktopName = "Kaiteki";
    genericName = "Micro-blogging client";
    comment = meta.description;
    categories = [ "Network" "InstantMessaging" "GTK" ];
  };

  sourceRoot = "source/src/kaiteki";

  postInstall = ''
    wrapProgram $out/bin/kaiteki \
      --prefix PATH : "${xdg-user-dirs}/bin"

    FAV=$out/app/data/flutter_assets/assets/icon.png
    ICO=$out/share/icons

    install -D $FAV $ICO/kaiteki.png
    for s in 24 32 42 64 128 256 512; do
      D=$ICO/hicolor/''${s}x''${s}/apps
      mkdir -p $D
      convert $FAV -resize ''${s}x''${s} $D/kaiteki.png
    done

    mkdir $out/share/applications
    cp $desktopItem/share/applications/*.desktop $out/share/applications
    substituteInPlace $out/share/applications/*.desktop \
      --subst-var out
  '';

  meta = with lib; {
    description = "The comfy Fediverse client";
    homepage = "https://craftplacer.moe/projects/kaiteki/";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
  };
}
