# DEBUGGING:
# - MUJOCO_GL=osmesa PYOPENGL_PLATFORM=osmesa ./result/bin/mootube
#   - gets further than before. now "AttributeError: 'NoneType' object has no attribute 'glGetError'"
{ lib
, fetchFromGitHub
, desktop-file-utils
, gettext
, glib
, gobject-introspection
, gtk3
, libnotify
, pkg-config
, python3
, wrapGAppsHook
, mesa
, freeglut
, libGLU
, libGL
, libdrm
, glfw
, pango
}:

python3.pkgs.buildPythonApplication rec {
  pname = "mootube";
  version = "unstable-2022-08-28";

  # format = "setuptools";

  src = fetchFromGitHub {
    owner = "ninebysix";
    repo = "MooTube";
    rev = "f6e207b9e22fbe0d757cbc008e1b27106b6e627e";
    hash = "sha256-pQA62vOQYXyGRa8UITOncDIK2q4xgSOM5zhLAzwpn4U=";
  };

  postPatch = ''
    # 1. prevent installer from asserting in `parse_entrypoints`.
    #    src/app.py *is* the entry point. it launches the program when that file is imported.
    #    this is contrary to what the packaging logic expects: an entry point which is a function.
    # 2. python-mpv dep is actually just `mpv`
    substituteInPlace setup.py \
      --replace 'mootube=src.app' 'mootube=src.app:MooTube' \
      --replace 'python-mpv' 'mpv'
  '';

  nativeBuildInputs = [
    glib
    # pkg-config
    wrapGAppsHook
    # gettext
    # glib # for glib-compile-resources
    # desktop-file-utils
    gobject-introspection
    pkg-config
  ];

  buildInputs = [
    glib
    gtk3
    glfw
    pango
  ];

  propagatedBuildInputs = with python3.pkgs; [
    flit-core
    pygobject3
    pyopengl
    # beautifulsoup4
    # brotli
    # cloudscraper
    # dateparser
    # emoji
    # keyring
    # lxml
    # python-magic
    # natsort
    # piexif
    pillow
    mpv
    youtube-search-python
    ytmusicapi
    # pure-protobuf
    # rarfile
    # unidecode
    mesa
    mesa.osmesa
    freeglut libGLU libGL
    libdrm
  ];

  # postInstall = ''
  #   wrapProgram $out/bin/mootube --prefix PYTHONPATH : "$PYTHONPATH"
  # '';

  dontWrapGApps = true;

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';


  doCheck = false;

  # pythonImportsCheck = ["mootube"];

  meta = with lib; {
    description = "YouTube App for Mobile Linux";
    homepage = "https://github.com/ninebysix/MooTube";
    license = licenses.mit;
    maintainers = with maintainers; [ colinsane ];
  };
}
