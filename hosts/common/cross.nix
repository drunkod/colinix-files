# cross compiling

# - for edge-casey things, see in nixpkgs:
#   - `git show da9a9a440415b236f22f57ba67a24ab3fb53f595`
#     - e.g. `mesonEmulatorHook`, `depsBuildBuild`, `python3.pythonForBuild`
#   - <doc/stdenv/cross-compilation.chapter.md>
#     - e.g. `makeFlags = [ "CC=${stdenv.cc.targetPrefix}cc" ];`
#
# build a particular package as evaluated here with:
# - toplevel: `nix build '.#host-pkgs.moby-cross.xdg-utils'`
# - scoped:   `nix build '.#host-pkgs.moby-cross.gnome.mutter'`
# - python:   `nix build '.#host-pkgs.moby-cross.python310Packages.pandas'`
# - perl:     `nix build '.#host-pkgs.moby-cross.perl536Packages.ModuleBuild'`
# - qt:       `nix build '.#host-pkgs.moby-cross.qt5.qtbase'`
# - qt:       `nix build '.#host-pkgs.moby-cross.libsForQt5.phonon'`
# most of these can be built in a nixpkgs source root like:
# - `nix build '.#pkgsCross.aarch64-multiplatform.xdg-utils'`
#
# tracking issues, PRs:
# - libuv tests fail: <https://github.com/NixOS/nixpkgs/issues/190807>
#   - last checked: 2023-02-07
#   - opened: 2022-09-11
# - perl Module Build broken: <https://github.com/NixOS/nixpkgs/issues/66741>
#   - last checked: 2023-02-07
#   - opened: 2019-08
# - perl536Packages.Testutf8 fails to cross: <https://github.com/NixOS/nixpkgs/issues/198548>
#   - last checked: 2023-02-07
#   - opened: 2022-10
# - python310Packages.psycopg2: <https://github.com/NixOS/nixpkgs/issues/210265>
#   - last checked: 2023-02-06
#   - i have a potential fix:
#     """
#       i was able to just add `postgresql` to the `buildInputs`  (so that it's in both `buildInputs` and `nativeBuildInputs`):
#       it fixed the build for `pkgsCross.aarch64-multiplatform.python310Packages.psycopg2` but not for `armv7l-hf-multiplatform` that this issue description calls out.
#
#       also i haven't deployed it yet to make sure this doesn't cause anything funky at runtime though.
#     """


{ config, lib, pkgs, ... }:

let
  # these are the overlays which we *also* pass through to the cross and emulated package sets.
  # TODO: refactor to not specify same overlay in multiple places (here and flake.nix).
  overlays = [
    (import ./../../overlays/pkgs.nix)
    (import ./../../overlays/pins.nix)
  ];
  mkCrossFrom = localSystem: pkgs:
    import pkgs.path {
      inherit localSystem;  # localSystem is equivalent to buildPlatform
      crossSystem = pkgs.stdenv.hostPlatform.system;
      inherit (config.nixpkgs) config;
      inherit overlays;
    };
  mkEmulated = pkgs:
    import pkgs.path {
      localSystem = pkgs.stdenv.hostPlatform.system;
      inherit (config.nixpkgs) config;
      inherit overlays;
    };
in
{
  # options = {
  #   perlPackageOverrides = lib.mkOption {
  #   };
  # };

  config = {
    # the configuration of which specific package set `pkgs.cross` refers to happens elsewhere;
    # here we just define them all.
    nixpkgs.overlays = [
      (next: prev: {
        # non-emulated packages build *from* local *for* target.
        # for large packages like the linux kernel which are expensive to build under emulation,
        # the config can explicitly pull such packages from `pkgs.cross` to do more efficient cross-compilation.
        crossFrom."x86_64-linux" = mkCrossFrom "x86_64-linux" prev;
        crossFrom."aarch64-linux" = mkCrossFrom "aarch64-linux" prev;

        emulated = mkEmulated prev;
      })
      (next: prev:
        let
          emulated = prev.emulated;
        in {
          # packages which don't cross compile
          inherit (emulated)
            # adwaita-qt  # psqlodbc
            apacheHttpd_2_4  # `configure: error: Size of "void *" is less than size of "long"`
            appstream  # meson.build:139:0: ERROR: Program 'gperf' not found or not executable
            colord  # (meson) ERROR: An exe_wrapper is needed but was not found. Please define one in cross file and check the command and/or add it to PATH.
            # duplicity  # python3.10-s3transfer
            flatpak  # No package 'libxml-2.0' found
            fwupd-efi  # efi/meson.build:162:0: ERROR: Program or command 'gcc' not found or not executable
            gmime3  # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
            # gnome-tour
            # XXX: gnustep members aren't individually overridable, because the "scope" uses `rec` such that members don't see overrides
            gnustep  # gnustep.base: "configure: error: Your compiler does not appear to implement the -fconstant-string-class option needed for support of strings."
            # grpc
            gvfs  # meson.build:312:2: ERROR: Assert failed: http required but libxml-2.0 not found
            # hdf5  # configure: error: cannot run test program while cross compiling
            # http2
            ibus  # configure.ac:152: error: possibly undefined macro: AM_PATH_GLIB_2_0
            kitty  # "FileNotFoundError: [Errno 2] No such file or directory: 'pkg-config'"
            libchamplain  # "failed to produce output path for output 'devdoc'"
            libgccjit  # "../../gcc-9.5.0/gcc/jit/jit-result.c:52:3: error: 'dlclose' was not declared in this scope"
            libgweather  # "Run-time dependency vapigen found: NO (tried pkgconfig)"
            libjcat  # data/tests/meson.build:10:0: ERROR: Program 'gnutls-certtool certtool' not found or not executable
            # libsForQt5  # qtbase  # make: g++: No such file or directory
            libtiger  # "src/tiger_internal.h:24:10: fatal error: pango/pango.h: No such file or directory"
            notmuch  # "Error: The dependencies of notmuch could not be satisfied"  (xapian, gmime, glib, talloc)
            perlInterpreters  # perl5.36.0-Module-Build perl5.36.0-Test-utf8 (see tracking issues ^)
            phosh  # libadwaita-1 not found
            # qgnomeplatform
            # qtbase
            qt5  # qt5.qtx11extras fails, but we can't selectively emulate it
            qt6  # "You need to set QT_HOST_PATH to cross compile Qt."
            sequoia  # "/nix/store/q8hg17w47f9xr014g36rdc2gi8fv02qc-clang-aarch64-unknown-linux-gnu-12.0.1-lib/lib/libclang.so.12: cannot open shared object file: No such file or directory"', /build/sequoia-0.27.0-vendor.tar.gz/bindgen/src/lib.rs:1975:31"
            # splatmoji
            squeekboard  # meson.build:1:0: ERROR: 'rust' compiler binary not defined in cross or native file
            twitter-color-emoji  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: pkg-config: command not found
            # unar has multiple failures:
            # - "configure: error: Your compiler does not appear to implement the -fconstant-string-class option needed for support of strings.  Please check for a more recent version or consider using --enable-nxconstantstring"
            # - "/nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: ar: command not found"
            unar
            visidata  # python3.10-psycopg2 python3.10-pandas python3.10-h5py
            webp-pixbuf-loader  # install phase: "Builder called die: Cannot wrap '/nix/store/kpp8qhzdjqgvw73llka5gpnsj0l4jlg8-gdk-pixbuf-aarch64-unknown-linux-gnu-2.42.10/bin/gdk-pixbuf-thumbnailer' because it is not an executable file"
            # webkitgtk_4_1  # requires nativeBuildInputs = perl.pkgs.FileCopyRecursive => perl5.36.0-Test-utf8
            # xdg-utils  # perl5.36.0-File-BaseDir / perl5.36.0-Module-Build
          ;

          # apacheHttpd_2_4 = prev.apacheHttpd_2_4.override {
          #   # fixes original error
          #   # new failure mode: "/nix/store/czvaa9y9ch56z53c0b0f5bsjlgh14ra6-apr-aarch64-unknown-linux-gnu-1.7.0-dev/share/build/libtool: line 1890: aarch64-unknown-linux-gnu-ar: command not found"
          #   inherit (emulated) stdenv;
          # };

          # mod_dnssd = prev.mod_dnssd.override {
          #   inherit (emulated) stdenv;
          # };
          apacheHttpdPackagesFor = apacheHttpd: self:
            let
              prevHttpdPkgs = prev.apacheHttpdPackagesFor apacheHttpd self;
            in prevHttpdPkgs // {
              # fixes "configure: error: *** Sorry, could not find apxs ***"
              mod_dnssd = prevHttpdPkgs.mod_dnssd.override {
                inherit (emulated) stdenv;
              };
            };
          # apacheHttpdPackagesFor = apacheHttpd: self:
          #   let
          #     prevHttpdPkgs = lib.fix (emulated.apacheHttpdPackagesFor apacheHttpd);
          #   in
          #     (prev.apacheHttpdPackagesFor apacheHttpd self) // {
          #       # inherit (prevHttpdPkgs) mod_dnssd;
          #       mod_dnssd = prevHttpdPkgs.mod_dnssd.override {
          #         inherit (self) apacheHttpd;
          #       };
          #     };
          # appstream = prev.appstream.override {
          #   # doesn't fix: "ld: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
          # appstream = prev.appstream.overrideAttrs (orig: {
          #   # fixes "Program 'gperf' not found or not executable"
          #   # does not fix "ERROR: An exe_wrapper is needed but was not found. Please define one in cross file and check the command and/or add it to PATH."
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gperf ];
          # });

          blueman = prev.blueman.overrideAttrs (orig: {
            # configure: error: ifconfig or ip not found, install net-tools or iproute2
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.iproute2 ];
          });
          brltty = prev.brltty.override {
            # configure: error: no acceptable C compiler found in $PATH
            inherit (emulated) stdenv;
          };
          browserpass = prev.browserpass.override {
            # fixes "qemu-aarch64: Could not open '/lib/ld-linux-aarch64.so.1': No such file or directory"
            inherit (emulated) buildGoModule;  # buildGoModule holds the stdenv
          };
          cantarell-fonts = prev.cantarell-fonts.override {
            # fixes error where python3.10-skia-pathops dependency isn't available for the build platform
            inherit (emulated) stdenv;
          };
          cdrtools = prev.cdrtools.override {
            # "configure: error: installation or configuration problem: C compiler cc not found."
            inherit (emulated) stdenv;
          };

          # colord = prev.colord.override {
          #   # doesn't fix: "ld: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };

          dante = prev.dante.override {
            # fixes: "configure: error: error: getaddrinfo() error value count too low"
            inherit (emulated) stdenv;
          };

          emacs = prev.emacs.override {
            # fixes "configure: error: cannot run test program while cross compiling"
            inherit (emulated) stdenv;
          };

          # flatpak = prev.flatpak.override {
          #   # doesn't fix: "ld: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };

          fuzzel = prev.fuzzel.override {
            # meson.build:100:0: ERROR: Dependency lookup for wayland-scanner with method 'pkgconfig' failed: Pkg-config binary for machine 0 not found. Giving up.
            inherit (emulated) stdenv;
          };

          # fwupd-efi = prev.fwupd-efi.override {
          #   # efi/meson.build:33:2: ERROR: Problem encountered: gnu-efi support requested, but headers were not found
          #   inherit (emulated) stdenv;
          # };
          fwupd = prev.fwupd.overrideAttrs (orig: {
            # solves (meson) "Run-time dependency libgcab-1.0 found: NO (tried pkgconfig and cmake)", and others.
            buildInputs = orig.buildInputs ++ [ next.gcab next.gnutls ];
            mesonFlags = (lib.remove "-Ddocs=enabled" orig.mesonFlags) ++ [ "-Ddocs=disabled" ];
            outputs = lib.remove "devdoc" orig.outputs;
          });
          # fwupd = prev.fwupd.override {
          #   # solves missing libgcab-1.0;
          #   # new error: "meson.build:449:4: ERROR: Command "/nix/store/n7xrj3pnrgcr8igx7lfhz8197y67bk7k-python3-aarch64-unknown-linux-gnu-3.10.9-env/bin/python3 po/test-deps" failed with status 1."
          #   inherit (emulated) stdenv;
          # };

          gcr_4 = prev.gcr_4.overrideAttrs (orig: {
            # fixes (meson): "ERROR: Program 'gpg2 gpg' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gnupg next.openssh ];
          });
          gthumb = prev.gthumb.overrideAttrs (orig: {
            # fixes (meson) "Program 'glib-mkenums mkenums' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          gmime = prev.gmime.overrideAttrs (orig: {
            # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
            configureFlags = orig.configureFlags ++ [ "ac_cv_have_iconv_detect_h=no" ];
          });

          # gmime3 = prev.gmime3.overrideAttrs (orig: {
          #   # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
          #   # unsolved: "ImportError: /nix/store/c190src4bjkfp7bdgc5sadnmvgzv7kxb-gobject-introspection-aarch64-unknown-linux-gnu-1.74.0/lib/gobject-introspection/giscanner/_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"
          #   configureFlags = orig.configureFlags ++ [ "ac_cv_have_iconv_detect_h=no" ];
          # });
          # gmime3 = prev.gmime3.override {
          #   # doesn't fix
          #   inherit (emulated) stdenv;
          # };

          gnome = prev.gnome.overrideScope' (self: super: {
            inherit (emulated.gnome)
              dconf-editor  # "error: Package `dconf' not found in specified Vala API directories or GObject-Introspection GIR directories"
              evolution-data-server  # "The 'perl' not found, not installing csv2vcard"
              gnome-shell  # "meson.build:128:0: ERROR: Program 'gjs' not found or not executable"
              gnome-settings-daemon  # subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable
              mutter  # meson.build:237:2: ERROR: Dependency "gbm" not found, tried pkgconfig  (it's provided by mesa)
            ;
            # dconf-editor = super.dconf-editor.override {
            #   # fails to fix original error
            #   inherit (emulated) stdenv;
            # };
            # dconf-editor = super.dconf-editor.overrideAttrs (orig: {
            #   # fails to fix original error
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.dconf ];
            # });
            evince = super.evince.overrideAttrs (orig: {
              # fixes (meson) "Run-time dependency gi-docgen found: NO (tried pkgconfig and cmake)"
              # inspired by gupnp
              outputs = [ "out" "dev" ]
                ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
              mesonFlags = orig.mesonFlags ++ [
                "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
              ];
            });
            # evolution-data-server = super.evolution-data-server.override {
            #   inherit (next) stdenv;
            # };
            # evolution-data-server = super.evolution-data-server.overrideAttrs (orig: {
            #   # fixes "The 'perl' not found, not installing csv2vcard"
            #   # doesn't fix "CMake Error: try_run() invoked in cross-compiling mode, please set the following cache variables appropriately"
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.perl ];
            # });
            file-roller = super.file-roller.override {
              # fixes "src/meson.build:106:0: ERROR: Program 'glib-compile-resources' not found or not executable"
              inherit (emulated) stdenv;
            };
            gnome-color-manager = super.gnome-color-manager.overrideAttrs (orig: {
              # fixes: "src/meson.build:3:0: ERROR: Program 'glib-compile-resources' not found or not executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            gnome-control-center = super.gnome-control-center.overrideAttrs (orig: {
              # fixes "subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # gnome-control-center = super.gnome-control-center.override {
            #   inherit (next) stdenv;
            # };
            # gnome-keyring = super.gnome-keyring.override {
            #   # does not fix original error
            #   inherit (next) stdenv;
            # };
            gnome-keyring = super.gnome-keyring.overrideAttrs (orig: {
              # fixes "configure.ac:374: error: possibly undefined macro: AM_PATH_LIBGCRYPT"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.libgcrypt next.openssh next.glib ];
            });
            gnome-remote-desktop = super.gnome-remote-desktop.overrideAttrs (orig: {
              # TODO: remove gnome-remote-desktop (wanted by gnome-control-center)
              # fixes: "Program gdbus-codegen found: NO"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # gnome-shell = super.gnome-shell.overrideAttrs (orig: {
            #   # fixes "meson.build:128:0: ERROR: Program 'gjs' not found or not executable"
            #   # does not fix "_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"  (python import failure)
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gjs next.gobject-introspection ];
            #   # try to reduce gobject-introspection/shew dependencies
            #   mesonFlags = [
            #     "-Dextensions_app=false"
            #     "-Dextensions_tool=false"
            #     "-Dman=false"
            #   ];
            #   # fixes "gvc| Build-time dependency gobject-introspection-1.0 found: NO"
            #   # inspired by gupnp_1_6
            #   # outputs = [ "out" "dev" ]
            #   #   ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
            #   # mesonFlags = [
            #   #   "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
            #   # ];
            # });
            # gnome-shell = super.gnome-shell.override {
            #   inherit (next) stdenv;
            # };
            # gnome-shell = super.gnome-shell.overrideAttrs (orig: {
            #   # does not solve original error
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.mesonEmulatorHook ];
            # });
            # gnome-settings-daemon = super.gnome-settings-daemon.overrideAttrs (orig: {
            #   # fixes "subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable"
            #   # new error: "plugins/power/meson.build:22:0: ERROR: Dependency lookup for glib-2.0 with method 'pkgconfig' failed: Pkg-config binary for machine 0 not found. Giving up."
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            # });
            # gnome-settings-daemon = super.gnome-settings-daemon.overrideAttrs (orig: {
            #   # does not fix original error
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.mesonEmulatorHook ];
            # });
            gnome-session = super.gnome-session.overrideAttrs (orig: {
              # fixes: "gdbus-codegen not found or executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # gnome-terminal = super.gnome-terminal.override {
            #   # fixes: "meson.build:343:0: ERROR: Dependency "libpcre2-8" not found, tried pkgconfig"
            #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libglib-2.0.so: error adding symbols: file in wrong format"
            #   inherit (emulated) stdenv;
            # };
            gnome-terminal = super.gnome-terminal.overrideAttrs (orig: {
              # fixes "meson.build:343:0: ERROR: Dependency "libpcre2-8" not found, tried pkgconfig"
              buildInputs = orig.buildInputs ++ [ next.pcre2 ];
            });
            gnome-user-share = super.gnome-user-share.overrideAttrs (orig: {
              # fixes: meson.build:111:6: ERROR: Program 'glib-compile-schemas' not found or not executable
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # mutter = super.mutter.override {
            #   # DOES NOT FIX: "meson.build:237:2: ERROR: Dependency "gbm" not found, tried pkgconfig  (it's provided by mesa)"
            #   inherit (next) stdenv;
            # };
            # mutter = super.mutter.overrideAttrs (orig: {
            #   # fixes "meson.build:237:2: ERROR: Dependency "gbm" not found, tried pkgconfig  (it's provided by mesa)"
            #   # new error: "/nix/store/c190src4bjkfp7bdgc5sadnmvgzv7kxb-gobject-introspection-aarch64-unknown-linux-gnu-1.74.0/lib/gobject-introspection/giscanner/_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gobject-introspection next.wayland-scanner ];
            #   buildInputs = orig.buildInputs ++ [ next.mesa ];
            #   # disable docs building
            #   mesonFlags = lib.remove "-Ddocs=true" orig.mesonFlags;
            # });
            # mutter = super.mutter.overrideAttrs (orig: {
            #   # TODO: something seems to be propagating an *emulated* version of gobject-introspection into the build
            #   nativeBuildInputs =
            #     (lib.remove next.python3
            #       (lib.remove next.mesa orig.nativeBuildInputs)
            #     )
            #     ++ [
            #       next.gobject-introspection
            #       next.mesonEmulatorHook
            #       next.python3.pythonForBuild
            #       next.wayland-scanner
            #     ];
            #   buildInputs = (lib.remove next.gobject-introspection orig.buildInputs)
            #     ++ [ next.mesa ];
            #   # disable docs building
            #   mesonFlags = lib.remove "-Ddocs=true" orig.mesonFlags;
            # });
            # nautilus = super.nautilus.override {
            #   # fixes: "meson.build:123:0: ERROR: Dependency "libxml-2.0" not found, tried pkgconfig"
            #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libglib-2.0.so: error adding symbols: file in wrong format"
            #   inherit (emulated) stdenv;
            # };
            nautilus = super.nautilus.overrideAttrs (orig: {
              # fixes: "meson.build:123:0: ERROR: Dependency "libxml-2.0" not found, tried pkgconfig"
              buildInputs = orig.buildInputs ++ [ next.libxml2 ];
            });
          });

          gocryptfs = prev.gocryptfs.override {
            # fixes "error: hash mismatch in fixed-output derivation" (vendorSha256)
            inherit (emulated) buildGoModule;  # equivalent to stdenv
          };
          gupnp_1_6 = prev.gupnp_1_6.overrideAttrs (orig: {
            # fixes "subprojects/gi-docgen/meson.build:10:0: ERROR: python3 not found"
            # this patch is copied from the default gupnp.
            # TODO: upstream
            outputs = [ "out" "dev" ]
              ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
            mesonFlags = [
              "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
              "-Dintrospection=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
            ];
          });

          gst_all_1 = prev.gst_all_1 // {
            # gst-editing-services = prev.gst_all_1.gst-editing-services.override {
            #   # fixes "Run-time dependency gst-validate-1.0 found: NO"
            #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libgobject-2.0.so: error adding symbols: file in wrong format"
            #   inherit (emulated) stdenv;
            # };
            # XXX this feels risky; it propagates a (conflicting) gst-plugins to all consumers
            # gst-editing-services = emulated.gst_all_1.gst-editing-services;
            gst-editing-services = prev.gst_all_1.gst-editing-services.overrideAttrs (orig: {
              # fixes "Run-time dependency gst-validate-1.0 found: NO"
              buildInputs = orig.buildInputs ++ [ next.gst_all_1.gst-devtools ];
              mesonFlags = orig.mesonFlags ++ [
                # disable "python formatters" to avoid undefined references to Py_Initialize, etc.
                "-Dpython=disabled"
              ];
            });
            inherit (emulated.gst_all_1) gst-plugins-good;
            # gst-plugins-good = prev.gst_all_1.gst-plugins-good.override {
            #   # when invoked with `qt5Support = true`, qtbase shows up in both buildInputs and nativeBuildInputs
            #   # if these aren't identical, then qt complains: "Error: detected mismatched Qt dependencies"
            #   # doesn't fix the original error.
            #   inherit (emulated) stdenv;
            #   # qt5Support = true;
            # };
          };
          # gvfs = prev.gvfs.overrideAttrs (orig: {
          #   # meson.build:312:2: ERROR: Assert failed: http required but libxml-2.0 not found
          #   # nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.libxml2 prev.mesonEmulatorHook ];
          #   # TODO: gvfs 1.50.2 -> 1.50.3 upgrade is upstreamed, and fixed cross compilation
          #   version = "1.50.3";
          #   src = next.fetchurl {
          #     url = "mirror://gnome/sources/gvfs/1.50/gvfs-1.50.3.tar.xz";
          #     sha256 = "aJcRnpe7FgKdJ3jhpaVKamWSYx+LLzoqHepO8rAYA/0=";
          #   };
          #   patches = [
          #     # Hardcode the ssh path again.
          #     # https://gitlab.gnome.org/GNOME/gvfs/-/issues/465
          #     (next.fetchpatch2 {
          #       url = "https://gitlab.gnome.org/GNOME/gvfs/-/commit/8327383e262e1e7f32750a8a2d3dd708195b0f53.patch";
          #       hash = "sha256-ReD7qkezGeiJHyo9jTqEQNBjECqGhV9nSD+dYYGZWJ8=";
          #       revert = true;
          #     })
          #   ];
          # });
          # gvfs = prev.gvfs.override {
          #   # solves original config-time problem
          #   # new failure: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/3n0n1s5gb34lkckkr8ix5b7s5hz4n48v-libxml2-2.10.3/lib/libxml2.so: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };

          hdf5 = prev.hdf5.override {
            inherit (emulated) stdenv;
          };

          # ibus = prev.ibus.override {
          #   # "_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"
          #   inherit (emulated) stdenv;
          # };

          iio-sensor-proxy = prev.iio-sensor-proxy.overrideAttrs (orig: {
            # fixes "./autogen.sh: line 26: gtkdocize: not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib next.gtk-doc ];
          });

          # kitty = prev.kitty.override {
          #   # does not solve original error
          #   inherit (emulated) stdenv;
          # };

          # libchamplain = prev.libchamplain.override {
          #   # fails: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libglib-2.0.so: error adding symbols: file in wrong format";
          #   inherit (emulated) stdenv;
          # };
          # libgweather = prev.libgweather.override {
          #   # solves original problem
          #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libgio-2.0.so: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
          libHX = prev.libHX.overrideAttrs (orig: {
            # "Can't exec "libtoolize": No such file or directory at /nix/store/r4fvx9hazsm0rdm7s393zd5v665dsh1c-autoconf-2.71/share/autoconf/Autom4te/FileUtils.pm line 294."
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.libtool ];
          });
          # libjcat = prev.libjcat.override {
          #   # fixes original error
          #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libgio-2.0.so: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };

          librest = prev.librest.overrideAttrs (orig: {
            # fixes "You must have gtk-doc >= 1.13 installed to build documentation"
            #   by removing the "--enable-gtk-doc" flag
            configureFlags = [ "--with-ca-certificates=/etc/ssl/certs/ca-certificates.crt" ];
          });
          librest_1_0 = prev.librest_1_0.overrideAttrs (orig: {
            # fixes (meson) "Run-time dependency gi-docgen found: NO (tried pkgconfig and cmake)"
            # inspired by gupnp
            outputs = [ "out" "dev" ]
              ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
            mesonFlags = orig.mesonFlags ++ [
              "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
            ];
          });
          libsForQt5 = prev.libsForQt5.overrideScope' (self: super: {
            qgpgme = super.qgpgme.overrideAttrs (orig: {
              # fix so it can find the MOC compiler
              # it looks like it might not *need* to propagate qtbase, but so far unclear
              nativeBuildInputs = orig.nativeBuildInputs ++ [ self.qtbase ];
              propagatedBuildInputs = lib.remove self.qtbase orig.propagatedBuildInputs;
            });
            phonon = super.phonon.overrideAttrs (orig: {
              # fixes "ECM (required version >= 5.60), Extra CMake Modules"
              buildInputs = orig.buildInputs ++ [ next.extra-cmake-modules ];
            });
          });

          # libtiger = prev.libtiger.override {
          #   # fails to fix: "src/tiger_internal.h:24:10: fatal error: pango/pango.h: No such file or directory"
          #   inherit (emulated) stdenv;
          # };
          # libtiger = prev.libtiger.overrideAttrs (orig: {
          #   # fails to fix: "src/tiger_internal.h:24:10: fatal error: pango/pango.h: No such file or directory"
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.libkate next.cairo next.pango ];
          # });

          libuv = prev.libuv.overrideAttrs (orig: {
            # 2 tests fail:
            # - not ok 261 - tcp_bind6_error_addrinuse
            # - not ok 267 - tcp_bind_error_addrinuse_listen
            doCheck = false;
          });

          ncftp = prev.ncftp.override {
            # fixes: "ar: No such file or directory"
            inherit (emulated) stdenv;
          };
          networkmanager-fortisslvpn = prev.networkmanager-fortisslvpn.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          # networkmanager-iodine = prev.networkmanager-iodine.overrideAttrs (orig: {
          #   # fails to fix "configure.ac:58: error: possibly undefined macro: AM_GLIB_GNU_GETTEXT"
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gettext ];
          # });
          networkmanager-iodine = prev.networkmanager-iodine.override {
            # fixes "configure.ac:58: error: possibly undefined macro: AM_GLIB_GNU_GETTEXT"
            inherit (emulated) stdenv;
          };
          networkmanager-l2tp = prev.networkmanager-l2tp.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            # fixes "gtk4-builder-tool: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib next.gtk4 ];
          });
          networkmanager-openconnect = prev.networkmanager-openconnect.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          networkmanager-openvpn = prev.networkmanager-openvpn.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          networkmanager-sstp = prev.networkmanager-sstp.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          networkmanager-vpnc = prev.networkmanager-vpnc.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          nheko = prev.nheko.overrideAttrs (orig: {
            # fixes "fatal error: lmdb++.h: No such file or directory
            buildInputs = orig.buildInputs ++ [ next.lmdbxx ];
          });
          # notmuch = prev.notmuch.override {
          #   # fails to solve original error
          #   inherit (emulated) stdenv;
          # };
          obex_data_server = prev.obex_data_server.override {
            # fixes "/nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 2: --prefix=ods_manager: command not found"
            inherit (emulated) stdenv;
          };
          openfortivpn = prev.openfortivpn.override {
            # fixes "checking for /proc/net/route... configure: error: cannot check for file existence when cross compiling"
            inherit (emulated) stdenv;
          };
          ostree = prev.ostree.override {
            # fixes "configure: error: Need GPGME_PTHREAD version 1.1.8 or later"
            inherit (emulated) stdenv;
          };
          pam_mount = prev.pam_mount.overrideAttrs (orig: {
            # fixes: "perl: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.perl ];
          });

          # perlPackageOverrides = _perl: {
          #   inherit (pkgs.emulated.perl.pkgs)
          #     Testutf8
          #   ;
          # };

          phoc = prev.phoc.override {
            # fixes "Program wayland-scanner found: NO"
            inherit (emulated) stdenv;
          };
          # phosh = prev.phosh.override {
          #   # fixes original error.
          #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/2bzd39fbsifidd667s7x930d0b7pm3qx-pango-1.50.12/lib/libpangocairo-1.0.so: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
          phosh-mobile-settings = prev.phosh-mobile-settings.override {
            # fixes "meson.build:26:0: ERROR: Dependency "phosh-plugins" not found, tried pkgconfig"
            inherit (emulated) stdenv;
          };
          pipewire = prev.pipewire.overrideAttrs (orig: {
            # fix `spa/plugins/bluez5/meson.build:41:0: ERROR: Program 'gdbus-codegen' not found or not executable`
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          psqlodbc = prev.psqlodbc.override {
            # fixes "configure: error: odbc_config not found (required for unixODBC build)"
            inherit (emulated) stdenv;
          };

          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (py-next: py-prev: {
              defcon = py-prev.defcon.overridePythonAttrs (orig: {
                # TODO: diagnose and upstream
                nativeBuildInputs = orig.nativeBuildInputs ++ orig.nativeCheckInputs;
              });
              executing = py-prev.executing.overridePythonAttrs (orig: {
                # TODO: confirm & upstream
                # test has an assertion that < 1s of CPU time elapsed => flakey
                disabledTestPaths = orig.disabledTestPaths or [] ++ [
                  # "tests/test_main.py::TestStuff::test_many_source_for_filename_calls"
                  "tests/test_main.py"
                ];
              });
              # h5py = py-prev.h5py.overridePythonAttrs (orig: {
              #   # XXX: can't upstream until its dependency, hdf5, is fixed. that looks TRICKY.
              #   # - the `setup_configure.py` in h5py tries to dlopen (and call into) the hdf5 lib to query the version and detect features like MPI
              #   # - it could be patched with ~10 LoC in the HDF5LibWrapper class.
              #   #
              #   # expose numpy and hdf5 as available at build time
              #   nativeBuildInputs = orig.nativeBuildInputs ++ orig.propagatedBuildInputs ++ orig.buildInputs;
              #   buildInputs = [];
              #   # HDF5_DIR = "${hdf5}";
              # });
              mutatormath = py-prev.mutatormath.overridePythonAttrs (orig: {
                # TODO: diagnose and upstream
                nativeBuildInputs = orig.nativeBuildInputs or [] ++ orig.nativeCheckInputs;
              });
              pandas = py-prev.pandas.overridePythonAttrs (orig: {
                # TODO: upstream
                # XXX: we only actually need numpy when building in ~/nixpkgs repo: not sure why we need all the propagatedBuildInputs here.
                # nativeBuildInputs = orig.nativeBuildInputs ++ [ py-next.numpy ];
                nativeBuildInputs = orig.nativeBuildInputs ++ orig.propagatedBuildInputs;
              });
              psycopg2 = py-prev.psycopg2.overridePythonAttrs (orig: {
                # TODO: upstream  (see tracking issue)
                #
                # psycopg2 *links* against libpg, so we need the host postgres available at build time!
                # present-day nixpkgs only includes it in nativeBuildInputs
                buildInputs = orig.buildInputs ++ [ next.postgresql ];
              });
              s3transfer = py-prev.s3transfer.overridePythonAttrs (orig: {
                # tests explicitly expect host CPU == build CPU
                # Bail out! ERROR:../plugins/core.c:221:qemu_plugin_vcpu_init_hook: assertion failed: (success)
                # Bail out! ERROR:../accel/tcg/cpu-exec.c:954:cpu_exec: assertion failed: (cpu == current_cpu)
                disabledTestPaths = orig.disabledTestPaths ++ [
                  # "tests/functional/test_processpool.py::TestProcessPoolDownloader::test_cleans_up_tempfile_on_failure"
                  "tests/functional/test_processpool.py"
                  # "tests/unit/test_compat.py::TestBaseManager::test_can_provide_signal_handler_initializers_to_start"
                  "tests/unit/test_compat.py"
                ];
              });
              # skia-pathops = ?
              #   it tries to call `cc` during the build, but can't find it.
            })
          ];
          # qt5 = prev.qt5.overrideScope' (self: super: {
          #   qtbase = super.qtbase.override {
          #     inherit (emulated) stdenv;
          #   };
          #   qtx11extras = super.qtx11extras.override {
          #     # "Project ERROR: Cannot run compiler 'g++'";
          #     # this fails an assert though, where the cross qt now references the emulated qt.
          #     inherit (emulated.qt5) qtModule;
          #   };
          # });
          # qt6 = prev.qt6.overrideScope' (self: super: {
          #   qtbase = super.qtbase.override {
          #     # fixes: "You need to set QT_HOST_PATH to cross compile Qt."
          #     inherit (emulated) stdenv;
          #   };
          # });
          rapidfuzz-cpp = prev.rapidfuzz-cpp.overrideAttrs (orig: {
            # fixes "error: could not find git for clone of catch2-populate"
            buildInputs = orig.buildInputs or [] ++ [ next.catch2_3 ];
          });
          re2 = (prev.re2.override {
            # fixes: "FAILED: CMakeFiles/test.util"
            inherit (emulated) stdenv;
          }).overrideAttrs (orig: {
            # exhaustive{,1,2}_test times out after 1500s.
            # this is after exhaustive3_test takes 600s to pass.
            doCheck = false;
          });
          rmlint = prev.rmlint.override {
            # fixes "Checking whether the C compiler works... no"
            inherit (emulated) stdenv;
          };
          # sequoia = prev.sequoia.override {
          #   # fails to fix original error
          #   inherit (emulated) stdenv;
          # };

          # squeekboard = prev.squeekboard.overrideAttrs (orig: {
          #   # fixes: "meson.build:1:0: ERROR: 'rust' compiler binary not defined in cross or native file"
          #   # new error: "meson.build:1:0: ERROR: Rust compiler rustc --target aarch64-unknown-linux-gnu -C linker=aarch64-unknown-linux-gnu-gcc can not compile programs."
          #   mesonFlags =
          #     let
          #       # ERROR: 'rust' compiler binary not defined in cross or native file
          #       crossFile = next.writeText "cross-file.conf" ''
          #         [binaries]
          #         rust = [ 'rustc', '--target', '${next.rust.toRustTargetSpec next.stdenv.hostPlatform}' ]
          #       '';
          #     in
          #       orig.mesonFlags or [] ++ lib.optionals (next.stdenv.hostPlatform != next.stdenv.buildPlatform) [ "--cross-file=${crossFile}" ];
          # });
          # squeekboard = prev.squeekboard.override {
          #   # new error: "gcc: error: unrecognized command line option '-m64'"
          #   inherit (emulated) stdenv;
          # };

          strp = prev.srtp.overrideAttrs (orig: {
            # roc_driver test times out after 30s
            doCheck = false;
          });
          sysprof = prev.sysprof.overrideAttrs (orig: {
            # fixes: "src/meson.build:12:2: ERROR: Program 'gdbus-codegen' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          tpm2-abrmd = prev.tpm2-abrmd.overrideAttrs (orig: {
            # fixes "configure: error: *** gdbus-codegen is required to build tpm2-abrmd; No package 'gio-unix-2.0' found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          tracker-miners = prev.tracker-miners.override {
            # fixes "meson.build:183:0: ERROR: Can not run test applications in this cross environment."
            inherit (emulated) stdenv;
          };
          # twitter-color-emoji = prev.twitter-color-emoji.override {
          #   # fails to fix original error
          #   inherit (emulated) stdenv;
          # };

          # unar = (prev.unar.override {
          #   # fixes "ar: command not found"
          #   # new error: "gcc: error: unrecognized command line option '-fobjc-runtime=gnustep-2.0'"
          #   inherit (emulated) stdenv;
          # });
          unixODBCDrivers = prev.unixODBCDrivers // {
            # TODO: should this package be deduped with toplevel psqlodbc in upstream nixpkgs?
            psql = prev.unixODBCDrivers.psql.override {
              # fixes "configure: error: odbc_config not found (required for unixODBC build)"
              inherit (emulated) stdenv;
            };
            # psql = prev.unixODBCDrivers.psql.overrideAttrs (orig: {
            #   # fixes "configure: error: odbc_config not found (required for unixODBC build)"
            #   # new error: "/nix/store/h3ms3h95rbj5p8yhxfhbsbnxgvpnb8w0-aarch64-unknown-linux-gnu-binutils-2.39/bin/aarch64-unknown-linux-gnu-ld: /nix/store/6h6z98qvg5k8rsqpivi42r5008zjfp2v-unixODBC-2.3.11/lib/libodbcinst.so: error adding symbols: file in wrong format"
            #   nativeBuildInputs = orig.nativeBuildInputs or [] ++ orig.buildInputs;
            # });
          };

          vlc = prev.vlc.overrideAttrs (orig: {
            # fixes: "configure: error: could not find the LUA byte compiler"
            # fixes: "configure: error: protoc compiler needed for chromecast was not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.lua5 next.protobuf ];
            # fix that it can't find the c compiler
            # makeFlags = orig.makeFlags or [] ++ [ "CC=${prev.stdenv.cc.targetPrefix}cc" ];
            BUILDCC = "${prev.stdenv.cc}/bin/${prev.stdenv.cc.targetPrefix}cc";
          });
          vpnc = prev.vpnc.overrideAttrs (orig: {
            # fixes "perl: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.perl ];
          });
          xdg-desktop-portal-gtk = prev.xdg-desktop-portal-gtk.overrideAttrs (orig: {
            # fixes "No package 'xdg-desktop-portal' found"
            buildInputs = orig.buildInputs ++ [ next.xdg-desktop-portal ];
          });
          xdg-desktop-portal-gnome = prev.xdg-desktop-portal-gnome.overrideAttrs (orig: {
            # fixes: "data/meson.build:33:5: ERROR: Program 'msgfmt' not found or not executable"
            # fixes: "src/meson.build:25:0: ERROR: Program 'gdbus-codegen' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gettext next.glib ];
          });
          # webp-pixbuf-loader = prev.webp-pixbuf-loader.override {
          #   # fixes "Builder called die: Cannot wrap '/nix/store/kpp8qhzdjqgvw73llka5gpnsj0l4jlg8-gdk-pixbuf-aarch64-unknown-linux-gnu-2.42.10/bin/gdk-pixbuf-thumbnailer' because it is not an executable file"
          #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/2syg6jxk8zi1zkpqvkxkz87x8sl27c6b-gdk-pixbuf-2.42.10/lib/libgdk_pixbuf-2.0.so: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
      })
    ];
  };
}
