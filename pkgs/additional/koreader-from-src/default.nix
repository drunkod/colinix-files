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
, sdcv
, SDL2
, substituteAll
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
  ] ++ (builtins.map
    (s: fetchgit (
      {
        leaveDotGit = true;  # maybe not needed, but we'd need another way to query the rev during build process below
        deepClone = true;  # probably not needed
      } // s
    ))
    sources.thirdparty
  );

  patches = [
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
      stamp_dir="base/thirdparty/$lib/build/x86_64-unknown-linux-gnu/git_checkout/stamp"
      echo "creating stamp in $stamp_dir for rev $rev"
      mkdir -p "$stamp_dir"
      # koreader-base decides whether to redo the git checkout based on a timestamp compare of these two stamp files
      touch -d "last week" "$stamp_dir/$lib-gitinfo-$rev.txt"
      touch -d "next week" "$stamp_dir/$lib-gitclone-lastrun.txt"

      # koreader would copy the checkout into this build/working directory,
      # but because we spoof the stamps to work around other git errors,
      # copy it there on koreader's behalf
      prefix="base/thirdparty/$lib/build/x86_64-unknown-linux-gnu/$lib-prefix"
      mkdir -p "$prefix/src"
      cp -R "$lib_src" "$prefix/src/$lib"
      # src dir needs to be writable for koreader to apply its own patches
      chmod u+w -R "$prefix/src/$lib"
    }

  '' + builtins.concatStringsSep "\n" (builtins.map
    (l: ''install_lib "${l.name}" "${l.rev}"'')
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
