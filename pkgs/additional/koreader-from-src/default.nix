{ lib, stdenv
, autoconf
, automake
, buildPackages
, cmake
, git
, libtool
, makeWrapper
, fetchFromGitHub
, fetchgit
, fetchurl
, dpkg
, glib
, gnutar
, gtk3-x11
, luajit
# , lua51Packages
, perl
, pkg-config
, python3
, ragel
, sdcv
, SDL2
, substituteAll
, which
}:
let
  # XXX: koreader assumes lua 5.1 in places -- is this really ok?
  luajit_lua52 = luajit.override { enable52Compat = true; };
  sources = import ./sources.nix;
  # luajson = luajit_lua52.pkgs.buildLuarocksPackage {
  #   pname = "luajson";
  #   version = "1.3.4-1";
  #   source = fetchgit {
  #     url = "https://github.com/harningt/luajson.git";
  #     rev = "1.3.4";
  #     hash = "sha256-JaJsjN5Gp+8qswfzl5XbHRQMfaCAJpWDWj9DYWJ0gEI=";
  #   };
  # };
  luaEnv = luajit_lua52.withPackages (ps: with ps; [
    luarocks
    (buildLuarocksPackage {
      pname = "luajson";
      version = "1.3.4-1";
      src = fetchgit {
        url = "https://github.com/harningt/luajson.git";
        rev = "1.3.4";
        hash = "sha256-JaJsjN5Gp+8qswfzl5XbHRQMfaCAJpWDWj9DYWJ0gEI=";
      };
      knownRockspec = (fetchurl {
        url = "mirror://luarocks/luajson-1.3.4-1.rockspec";
        hash = "sha256-+S4gfa6QaOMmOCDX8TxBq3kFWlbaEeiSMxCfefYakv0=";
      }).outPath;
      propagatedBuildInputs = [ lpeg ];
    })
  ]);
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
    # ./mupdf_dir.patch  #< TODO: needed?
    ./no_rm_build_dirs.patch
    ./lua-Spore-no-luajson.patch  #< TODO: test this at runtime! we ship luajson, but just don't expose it via luarocks...
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
    # lua51Packages.luarocks
    makeWrapper
    perl  # TODO: openssl might try to take a runtime dep on this; see nixpkg
    pkg-config
    python3
    ragel
    which
    # luajit_lua52.pkgs.luarocks
    luaEnv.pkgs.luarocks
  ];
  buildInputs = [
    glib
    gnutar
    gtk3-x11
    # luajit_lua52
    # luajson
    luaEnv
    sdcv
    SDL2
  ];

  postPatch =
  let
    env = "${buildPackages.coreutils}/bin/env";
  in ''
    substituteInPlace ../openssl/config --replace '/usr/bin/env' '${env}'

    chmod +x ../glib/gio/gio-querymodules-wrapper.py
    chmod +x ../glib/gio/tests/gengiotypefuncs.py
    chmod +x ../glib/gobject/tests/taptestrunner.py
    # need directory write perm in order to patchShebangs
    chmod u+w ../glib/{gio,gio/tests,glib,gobject/tests,tests}

    patchShebangs ../glib/gio/data-to-c.py
    patchShebangs ../glib/gio/gio-querymodules-wrapper.py
    patchShebangs ../glib/gio/tests/gengiotypefuncs.py
    patchShebangs ../glib/glib/update-gtranslit.py
    patchShebangs ../glib/gobject/tests/taptestrunner.py
    patchShebangs ../glib/tests/gen-casefold-txt.py
    patchShebangs ../glib/tests/gen-casemap-txt.py

    substituteInPlace ../glib/gio/gdbus-2.0/codegen/gdbus-codegen.in --replace '/usr/bin/env @PYTHON@' '@PYTHON@'
    substituteInPlace ../glib/glib/gtester-report.in --replace '/usr/bin/env @PYTHON@' '@PYTHON@'
    substituteInPlace ../glib/gobject/glib-genmarshal.in --replace '/usr/bin/env @PYTHON@' '@PYTHON@'
    substituteInPlace ../glib/gobject/glib-mkenums.in --replace '/usr/bin/env @PYTHON@' '@PYTHON@'
  '';

  dontConfigure = true;
  buildPhase = ''
    install_lib() {
      lib="$1"
      rev="$2"
      platform="$3"

      lib_src="../$lib"
      build_dir="base/thirdparty/$lib/build/$platform"

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
      stamp_dir="$build_dir/git_checkout/stamp"
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
      prefix="$build_dir/$lib-prefix"
      mkdir -p "$prefix/src"
      cp -R "$lib_src" "$prefix/src/$lib"
      # src dir needs to be writable for koreader to apply its own patches
      chmod u+w -R "$prefix/src/$lib"
    }

  '' + builtins.concatStringsSep "\n" (lib.mapAttrsToList
    (name: src:
      let
        # for machine-agnostic libraries (e.g. pure lua), koreader doesn't build them in a flavored directory
        machine = if src.machineAgnostic or false then "" else "x86_64-unknown-linux-gnu";
      in
        ''install_lib "${name}" "${src.source.rev}" "${machine}"''
    )
    sources.thirdparty
  ) + ''

    make TARGET=debian DEBIAN=1 SHELL=sh VERBOSE=1
  '';
  # XXX: ^ don't specify INSTALL_DIR="$out" as make arg because that conflicts with vars used by third-party libs
  # might be safe to specify that as an env var, though?

  installPhase = ''
    make TARGET=debian DEBIAN=1 update
  '';

  passthru = {
    inherit luaEnv;
  };

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
