{ lib
, fetchFromGitHub
, jellyfin-media-player
, libGL
, libX11
, libXrandr
, libvdpau
, mpv
, qt6
, SDL2
, stdenv
}:
jellyfin-media-player.overrideAttrs (upstream: {
  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-media-player";
    rev = "qt6";
    hash = "sha256-saR/P2daqjF0G8N7BX6Rtsb1dWGjdf5MPDx1lhoioEw=";
  };
  # nixos ships two patches:
  # - the first fixes "web paths" and has *mostly* been upstreamed  (so skip)
  # - the second disables auto-update notifications  (keep)
  patches = builtins.tail upstream.patches;
  buildInputs = [
    SDL2
    libGL
    libX11
    libXrandr
    libvdpau
    mpv
    qt6.qtbase
    qt6.qtwebchannel
    qt6.qtwebengine
    # qtx11extras
  ] ++ lib.optionals stdenv.isLinux [
    qt6.qtwayland
  ];

  meta = upstream.meta // {
    platforms = upstream.meta.platforms ++ [ "aarch64-linux" ];
  };
})
