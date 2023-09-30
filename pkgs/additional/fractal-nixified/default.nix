# Cargo.nix and crate-hashes.json were created with:
# - `nix shell -f https://github.com/kolloch/crate2nix/tarball/master`
#   - `crate2nix generate -f ~/ref/repos/gnome/fractal/Cargo.toml`
# or, once 0.11 reaches nixpkgs:
# - `nix run '.#crate2nix' -- generate -f ~/ref/repos/gnome/fractal/Cargo.toml`
#
# then:
# - `sed -i 's/target."curve25519_dalek_backend"/target."curve25519_dalek_backend" or ""/g' Cargo.nix`

{ pkgs
, buildPackages
, dbus-glib
, glib
, gst_all_1
, gtk4
, gtksourceview5
, libadwaita
, libshumate
, pipewire
, pkg-config
, rustPlatform
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
    defaultCrateOverrides = pkgs.defaultCrateOverrides // {
      fractal = attrs: attrs // {
        src = pkgs.fetchFromGitLab {
          domain = "gitlab.gnome.org";
          owner = "GNOME";
          repo = "fractal";
          rev = "350a65cb0a221c70fc3e4746898036a345ab9ed8";
          hash = "sha256-z6uURqMG5pT8rXZCv5IzTjXxtt/f4KUeCDSgk90aWdo=";
        };
      };

      clang-sys = attrs: attrs // {
        LIBCLANG_PATH = "${buildPackages.llvmPackages.libclang.lib}/lib";
      };
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
        verbose = true;
        CARGO_PKG_REPOSITORY = "nixpkgs";
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
