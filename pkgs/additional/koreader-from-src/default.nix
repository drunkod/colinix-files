{ lib, stdenv
, autoconf
, automake
, cmake
, fetchurl
, git
, libtool
, makeWrapper
, fetchgit
, fetchFromGitHub
, dpkg
, glib
, gnutar
, gtk3-x11
, luajit
, pkg-config
, ragel
, sdcv
, SDL2
, substituteAll
, which
}:
let
  luajit_lua52 = luajit.override { enable52Compat = true; };
  sources = import ./sources.nix;
in
stdenv.mkDerivation rec {
  pname = "koreader-from-src";
  version = "2023.06";
  srcs = [
    (fetchFromGitHub {
      owner = "koreader";
      repo = "koreader";
      fetchSubmodules = true;
      rev = "d350418367ddf39d752d05e0587e562d7d4af2c4";  # master
      hash = "sha256-ri5ckf21xDKf/X0p2c9wePTa6jh5u0BoUwpVdgpYpZw=";
      # rev = "v${version}";
      # hash = "sha256-gdf7AUTpIJ6T4H915YqRG1WzxYHrGmzX6X4dMriWzRA=";
      name = "koreader";
    })
  ] ++ (lib.mapAttrsToList
    (name: src: fetchgit (
      {
        inherit name;
      } // src.source // {
        # koreader sometimes specifies the rev as `tags/FOO`.
        # we need to remember that to place the repo where it expects, but we have to strip it here for fetchgit to succeed.
        rev = lib.removePrefix "tags/" src.source.rev;
      }
    ))
    sources.thirdparty
  );

  patches = [
    ./debug.patch
    ./mupdf_dir.patch  #< TODO: needed?
    ./mupdf_no_rm_build_dir.patch
    (substituteAll (
      {
        src = ./vendor-external-projects.patch;
      } // (lib.mapAttrs
        (_proj: source: fetchurl source)
        sources.externalProjects
      )
    ))
  ];

  sourceRoot = "koreader";

  nativeBuildInputs = [
    autoconf  # autotools is used by some thirdparty libraries
    automake
    cmake  # for koreader/base submodule
    dpkg
    git
    libtool
    makeWrapper
    pkg-config
    ragel
    which
    # luajit_lua52.pkgs.luarocks
  ];
  buildInputs = [
    glib
    gnutar
    gtk3-x11
    luajit_lua52
    sdcv
    SDL2
  ];

  dontConfigure = true;
  buildPhase = ''
    install_lib() {
      lib="$1"
      rev="$2"
      platform="$3"

      lib_src="../$lib"

      # link the nix clone into the directory koreader would use for checkout
      # ref="base/thirdparty/$l/build/git_checkout"
      # echo "linking thirdparty library $l $ref -> $deref"
      # mkdir -p "$ref"
      # ln -s "$deref" "$ref/$l"
      # mv "$deref" "$ref/$l"
      # cp -R "$deref" "$ref/$l"
      # needs to be writable for koreader to checkout it specific revision
      # chmod u+w -R "$ref/$l/.git"

      # koreader wants to clone each library into this git_checkout dir,
      # then checkout a specific revision,
      # and then copy that checkout into the build/working directory further down.
      # instead, we replicate that effect here, and by creating these "stamp" files
      # koreader will know to skip the `git clone` and `git checkout` calls.
      # the logic we're spoofing lives in koreader/base/thirdparty/cmake_modules/koreader_thirdparty_git.cmake
      stamp_dir="base/thirdparty/$lib/build/$platform/git_checkout/stamp"
      stamp_info="$stamp_dir/$lib-gitinfo-$rev.txt"
      stamp_clone="$stamp_dir/$lib-gitclone-lastrun.txt"
      echo "creating stamps for $lib: $stamp_clone > $stamp_info"
      # mkdir $(dirname ..) to handle the case where `$rev` contains slashes
      mkdir -p $(dirname "$stamp_info")
      # koreader-base decides whether to redo the git checkout based on a timestamp compare of these two stamp files
      touch -d "last week" $(dirname "$stamp_info")  #< XXX: necessary?
      touch -d "last week" "$stamp_info"
      touch -d "next week" "$stamp_clone"

      # koreader would copy the checkout into this build/working directory,
      # but because we spoof the stamps to work around other git errors,
      # copy it there on koreader's behalf
      prefix="base/thirdparty/$lib/build/$platform/$lib-prefix"
      mkdir -p "$prefix/src"
      cp -R "$lib_src" "$prefix/src/$lib"
      # src dir needs to be writable for koreader to apply its own patches
      chmod u+w -R "$prefix/src/$lib"
    }

  '' + builtins.concatStringsSep "\n" (lib.mapAttrsToList
    (name: src: ''install_lib "${name}" "${src.source.rev}" "${if src.buildInSource or false then "" else "x86_64-unknown-linux-gnu"}"'')
    sources.thirdparty
  ) + ''

    make TARGET=debian DEBIAN=1 INSTALL_DIR="$out" SHELL=sh VERBOSE=1
  '';

  installPhase = ''
    make TARGET=debian DEBIAN=1 INSTALL_DIR="$out" update
  '';

  meta = with lib; {
    homepage = "https://github.com/koreader/koreader";
    description =
      "An ebook reader application supporting PDF, DjVu, EPUB, FB2 and many more formats, running on Cervantes, Kindle, Kobo, PocketBook and Android devices";
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = platforms.linux;
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ colinsane contrun neonfuz];
  };
}
