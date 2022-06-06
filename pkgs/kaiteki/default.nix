{ lib
, fetchFromGitHub
, flutter
, makeDesktopItem
}:

flutter.mkFlutterApp rec {
  pname = "kaiteki";
  version = "unstable-2022-06-03";

  vendorHash = "sha256-y22Fvkm2sV0Gso7Z8yHlMU4wiHocytonGCB6GWhaqZo=";

  src = fetchFromGitHub {
    owner = "Kaiteki-Fedi";
    repo = "Kaiteki";
    rev = "0a322313071e4391949d23d9b006d74de65f58d9";
    hash = "sha256-ggDIbVwueS162m15TFaC6Tcg+0lpcVGi4x/O691sxR8";
  };

  desktopItems = [ (makeDesktopItem {
    name = "Kaiteki";
    exec = "kaiteki";
    icon = "kaiteki";
    desktopName = "Kaiteki";
    genericName = "Micro-blogging client";
    comment = meta.description;
    categories = [ "Network" "InstantMessaging" "GTK" ];
  }) ];

  sourceRoot = "source/src/kaiteki";

  meta = with lib; {
    description = "The comfy Fediverse client";
    homepage = "https://craftplacer.moe/projects/kaiteki/";
    license = licenses.agpl3Plus;
    # maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
  };
}
