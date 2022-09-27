{ lib
, fetchFromGitHub
, flutter
, makeDesktopItem
, xdg-user-dirs
}:

flutter.mkFlutterApp rec {
  pname = "kaiteki";
  version = "unstable-2022-08-31";

  # this hash seems unstable -- depends on other nixpkgs, perhaps?
  # vendorHash = "sha256-4DdtceIxj89ta12EhfxA2B5K9++LrKSA7ZzUb/NaaGs=";
  vendorHash = "sha256-OEDJSnXDNut/YZ+3cQ76KUBW/MaXcnirZDHu/n97108=";

  src = fetchFromGitHub {
    owner = "Kaiteki-Fedi";
    repo = "Kaiteki";
    # rev = "cf94ec55063cd7af20a37103fc40c588a634962f";
    # hash = "sha256-jtRT0Q4/i3dxRYcC6HPClL9Iw1PizkIUgswU1eusKig=";
    # past this hash Kaiteki introduces submodules for l10n stuff; not sure how to account for that yet.
    rev = "324077e4716ce996531457ec9c45fb3cc82820a0";
    hash = "sha256-qqVePcDnuc7SdPUhZtfcMGPzpemmZEvCNLqEbUDi2SA=";
  };

  nativeBuildInputs = [ xdg-user-dirs ];

  desktopItems = [ (makeDesktopItem {
    name = "Kaiteki";
    exec = "@out@/bin/kaiteki";
    icon = "kaiteki";
    desktopName = "Kaiteki";
    genericName = "Micro-blogging client";
    comment = meta.description;
    categories = [ "Network" "InstantMessaging" "GTK" ];
  }) ];

  sourceRoot = "source/src/kaiteki";

  postInstall = ''
    wrapProgram $out/bin/kaiteki \
      --prefix PATH : "${xdg-user-dirs}/bin"
  '';

  meta = with lib; {
    description = "The comfy Fediverse client";
    homepage = "https://craftplacer.moe/projects/kaiteki/";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
  };
}
