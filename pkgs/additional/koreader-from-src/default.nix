{ lib, stdenv
, cmake
, fetchurl
, git
, makeWrapper
, fetchFromGitHub
, dpkg
, glib
, gnutar
, gtk3-x11
, luajit
, sdcv
, SDL2
, writeText
}:
let
  luajit_lua52 = luajit.override { enable52Compat = true; };
  luajit-stamp = writeText "luajit-stamp" ''
    # This is a generated file and its contents are an internal implementation detail.
    # The download step will be re-executed if anything in this file changes.
    # No other meaning or use of this file is supported.

    method=
    command=
    source_dir=
    work_dir=/build/koreader/base/thirdparty/luajit/build/x86_64-unknown-linux-gnu/git_checkout
  '';
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
    (fetchFromGitHub {
      repo = "LuaJIT";
      owner = "LuaJIT";
      rev = "8635cbabf3094c4d8bd00578c7d812bea87bb2d3";
      hash = "sha256-os10rjBacalpDw2TkF/LEFL6xiQJkWCr+yqrY6XgSZo=";
      # rev = "224129a8e64bfa219d35cd03055bf03952f167f6";
      # hash = "sha256-ZxGRpUO9NYjC2fL0P24FOxui27xSvN4TA8r9Gukvfn8=";
      name = "thirdparty-luajit";
      leaveDotGit = true;
      deepClone = true;
    })
  ];

  sourceRoot = "koreader";

  nativeBuildInputs = [
    cmake
    dpkg
    git
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
    for l in $(ls .. | grep thirdparty- | sed 's/thirdparty-//')
    do
      deref=$(realpath "../thirdparty-$l")
      # deref="$PWD/../thirdparty-$l"

      # link the nix clone into the directory koreader would use for checkout
      # ref="base/thirdparty/$l/build/git_checkout"
      # echo "linking thirdparty library $l $ref -> $deref"
      # mkdir -p "$ref"
      # ln -s "$deref" "$ref/$l"
      # mv "$deref" "$ref/$l"
      # cp -R "$deref" "$ref/$l"
      # needs to be writable for koreader to checkout it specific revision
      # chmod u+w -R "$ref/$l/.git"

      # koreader would copy the checkout into this build/working directory,
      # but because we spoof the stamps to work around other git errors,
      # copy it there on koreader's behalf
      prefix="base/thirdparty/$l/build/x86_64-unknown-linux-gnu/$l-prefix"
      mkdir -p "$prefix/src"
      cp -R "$deref" "$prefix/src/$l"
      # src dir needs to be writable for koreader to apply its own patches
      chmod u+w -R "$prefix/src/$l"
    done

    # TODO: move this into the above loop, but we need to be able to read the commit dynamically
    echo "copying ${luajit-stamp}"
    mkdir -p "base/thirdparty/luajit/build/x86_64-unknown-linux-gnu/git_checkout/stamp"
    cp "${luajit-stamp}" "base/thirdparty/luajit/build/x86_64-unknown-linux-gnu/git_checkout/stamp/luajit-gitinfo-8635cbabf3094c4d8bd00578c7d812bea87bb2d3.txt"
    cp "${luajit-stamp}" "base/thirdparty/luajit/build/x86_64-unknown-linux-gnu/git_checkout/stamp/luajit-gitclone-lastrun.txt"
    # koreader-base decides whether to redo the git checkout based on a timestamp compare of these two stamp files
    touch -d "next week" "base/thirdparty/luajit/build/x86_64-unknown-linux-gnu/git_checkout/stamp/luajit-gitclone-lastrun.txt"

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
