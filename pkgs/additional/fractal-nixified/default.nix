# Cargo.nix and crate-hashes.json were created with:
# - `nix shell -f https://github.com/kolloch/crate2nix/tarball/master`
#   - `crate2nix generate -f ~/ref/repos/gnome/fractal/Cargo.toml`
# or, once 0.11 reaches nixpkgs:
# - `nix run '.#crate2nix' -- generate -f ~/ref/repos/gnome/fractal/Cargo.toml`
#
# then:
# - `sed -i 's/target."curve25519_dalek_backend"/target."curve25519_dalek_backend" or ""/g' Cargo.nix`

{ pkgs
, appstream-glib
, buildPackages
, cargo
, dbus-glib
, desktop-file-utils
, glib
, gst_all_1
, gtk4
, gtksourceview5
, libadwaita
, libshumate
, meson
, ninja
, openssl
, pipewire
, pkg-config
, rustPlatform
, sqlite
, wrapGAppsHook4
, xdg-desktop-portal
}:
let
  gtkDeps = attrs: attrs // {
    # see: <https://github.com/nix-community/crate2nix/issues/286>
    # gtk -sys packages declare their system dependencies in Cargo.toml like:
    # `[package.metadata.system-deps.gstreamer_1_0]`
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ dbus-glib gtk4 ];
    verbose = true;  #< doesn't seem to do anything
  };
  cargoNix = import ./Cargo.nix {
    inherit pkgs;
    release = false;
    rootFeatures = [ ];  #< avoids --cfg feature="default", simplifying the rustc CLI so that i can pass it around easier
    defaultCrateOverrides = pkgs.defaultCrateOverrides // {
      fractal = attrs: attrs // {
        src = pkgs.fetchFromGitLab {
          domain = "gitlab.gnome.org";
          owner = "GNOME";
          repo = "fractal";
          rev = "350a65cb0a221c70fc3e4746898036a345ab9ed8";
          hash = "sha256-z6uURqMG5pT8rXZCv5IzTjXxtt/f4KUeCDSgk90aWdo=";
        };
        codegenUnits = 256;  #< this does get plumbed, but doesn't seem to affect build speed
        outputs = [ "out" ];  # default is "out" and "lib", but that somehow causes cycles
        outputDev = [ "out" ];
        nativeBuildInputs = [
          glib
          gtk4
          meson
          ninja
          pkg-config
          desktop-file-utils
          appstream-glib
          wrapGAppsHook4
        ];
        buildInputs = [
          glib
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-bad
          gtk4
          gtksourceview5
          libadwaita
          openssl
          pipewire
          libshumate
          sqlite
          xdg-desktop-portal
        ];
        postPatch = ''
          substituteInPlace src/meson.build \
            --replace 'cargo_options,'  "" \
            --replace "cargo, 'build',"  "'bash', 'crate2nix_cmd.sh'," \
            --replace "'src' / rust_target" "'target/bin'"
        '';
        preBuild = ''
          build_bin() {
            # build_bin is what buildRustCrate would use to invoke rustc, but we want to drive the build
            # with meson instead. however, meson doesn't know how to plumb our rust dependencies into cargo,
            # so we still need to use build_bin for just one portion of the build.
            #
            # so, this mocks out the original build_bin:
            # - we patch upstream fractal to call our `crate2nix_cmd.sh` when it wants to compile the rust.
            # - we don't actually invoke meson (ninja) at all here, but rather in the `installPhase`.
            #   if we invoked it here, the whole build would just get re-done in installPhase anyway.
            #
            # rustc invocation copied from <pkgs/build-support/rust/build-rust-crate/lib.sh>
            echo "set -x" > crate2nix_cmd.sh
            echo "rmdir target/bin" >> crate2nix_cmd.sh
            echo "rmdir target" >> crate2nix_cmd.sh
            echo "ln -s ../target ." >> crate2nix_cmd.sh
            crate_name_=fractal
            main_file=../src/main.rs
            echo "rustc "\
              "--crate-name $crate_name_ "\
              "$main_file "\
              "--crate-type bin "\
              "$BIN_RUSTC_OPTS "\
              "--out-dir target/bin "\
              "-L dependency=target/deps "\
              "$LINK "\
              "$EXTRA_LINK_ARGS "\
              "$EXTRA_LINK_ARGS_BINS "\
              "$EXTRA_LIB "\
              "--cap-lints allow "\
              "$BUILD_OUT_DIR "\
              "$EXTRA_BUILD "\
              "$EXTRA_FEATURES "\
              "$EXTRA_RUSTC_FLAGS "\
              "--color ''${colors}" \
              >> crate2nix_cmd.sh
            }
        '';

        postConfigure = ''
          # copied from <pkgs/development/tools/build-managers/meson/setup-hook.sh>
          mesonFlags="--prefix=$prefix $mesonFlags"
          mesonFlags="\
              --libdir=''${!outputLib}/lib --libexecdir=''${!outputLib}/libexec \
              --bindir=''${!outputBin}/bin --sbindir=''${!outputBin}/sbin \
              --includedir=''${!outputInclude}/include \
              --mandir=''${!outputMan}/share/man --infodir=''${!outputInfo}/share/info \
              --localedir=''${!outputLib}/share/locale \
              -Dauto_features=''${mesonAutoFeatures:-enabled} \
              -Dwrap_mode=''${mesonWrapMode:-nodownload} \
              $mesonFlags"

          mesonFlags="''${crossMesonFlags+$crossMesonFlags }--buildtype=''${mesonBuildType:-plain} $mesonFlags"

          echo "meson flags: $mesonFlags ''${mesonFlagsArray[@]}"

          meson setup build $mesonFlags "''${mesonFlagsArray[@]}"
          cd build
        '';

        installPhase = "ninjaInstallPhase";
      };

      clang-sys = attrs: attrs // {
        LIBCLANG_PATH = "${buildPackages.llvmPackages.libclang.lib}/lib";
      };
      # TODO: these can be reduced
      gdk-pixbuf-sys = gtkDeps;
      gdk4-wayland-sys = gtkDeps;
      gdk4-x11-sys = gtkDeps;
      gio-sys = gtkDeps;
      gobject-sys = gtkDeps;
      gstreamer-audio-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ gst_all_1.gst-plugins-base ];
      };
      gstreamer-base-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ gst_all_1.gst-plugins-base ];
      };
      gstreamer-pbutils-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ gst_all_1.gst-plugins-base ];
      };
      gstreamer-play-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-base
        ];
      };
      gstreamer-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ gst_all_1.gst-plugins-base ];
      };
      gstreamer-video-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ gst_all_1.gst-plugins-base ];
      };
      gst-plugin-gtk4 = attrs: attrs // {
        # [package.metadata.capi.pkg_config]
        # requires_private = "gstreamer-1.0, gstreamer-base-1.0, gstreamer-video-1.0, gtk4, gobject-2.0, glib-2.0, gmodule-2.0"
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [
          gst_all_1.gst-plugins-base
          gst_all_1.gst-libav
          gtk4
          glib
        ];
        CARGO_PKG_REPOSITORY = "nixpkgs";
        # it wants `type = [ "cdylib" "rlib" ]` but that causes a link format failure on cross compilation
        #   (tries to link aarch64 gstgtk4.o file with the x86_64 linker).
        # default if unspecified it `type = [ "lib" ]`
        type = [ "rlib" ];
      };
      libadwaita-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ libadwaita ];
      };
      libshumate-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ libshumate gtk4 ];
      };
      libspa-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook ];
        buildInputs = [ pipewire ];

        # bindgenHook does the equivalent of this:
        # preConfigure = (attrs.preConfigure or "") + ''
        #   # export BINDGEN_EXTRA_CLANG_ARGS="$NIX_CFLAGS_COMPILE"
        #   export BINDGEN_EXTRA_CLANG_ARGS="$(< ${clang}/nix-support/cc-cflags) $(< ${clang}/nix-support/libc-cflags) $(< ${clang}/nix-support/libcxx-cxxflags) $NIX_CFLAGS_COMPILE"
        # '';
        # LIBCLANG_PATH = "${buildPackages.llvmPackages.libclang.lib}/lib";
      };
      libspa = attrs: attrs // {
        # not sure why the non-sys version of this crate needs pkg-config??
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ pipewire ];
      };
      pipewire-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook ];
        buildInputs = [ pipewire ];

        # bindgenHook does the equivalent of this:
        # preConfigure = (attrs.preConfigure or "") + ''
        #   # export BINDGEN_EXTRA_CLANG_ARGS="$NIX_CFLAGS_COMPILE"
        #   export BINDGEN_EXTRA_CLANG_ARGS="$(< ${clang}/nix-support/cc-cflags) $(< ${clang}/nix-support/libc-cflags) $(< ${clang}/nix-support/libcxx-cxxflags) $NIX_CFLAGS_COMPILE"
        # '';
        # LIBCLANG_PATH = "${buildPackages.llvmPackages.libclang.lib}/lib";
      };
      sourceview5-sys = attrs: attrs // {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ gtksourceview5 ];
      };
    };
    # defaultCrateOverrides = pkgs.defaultCrateOverrides // {
    #   js_int = attrs: attrs // {
    #     features = attrs.features ++ [ "serde" ];
    #   };
    #   serde = attrs: attrs // {
    #     features = attrs.features ++ [ "derive" "serde_derive" ];
    #   };
    # };
  };
in
  cargoNix.workspaceMembers.fractal.build
