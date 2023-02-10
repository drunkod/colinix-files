# cross compiling
# - for edge-casey things (e.g. `mesonEmulatorHook`, `depsBuildBuild`), see in nixpkgs:
#   `git show da9a9a440415b236f22f57ba67a24ab3fb53f595`
#
# build a particular package as evaluated here with:
# - toplevel: `nix build '.#host-pkgs.moby-cross.xdg-utils'`
# - scoped:   `nix build '.#host-pkgs.moby-cross.gnome.mutter'`
# - python:   `nix build '.#host-pkgs.moby-cross.python310Packages.pandas'`
# - perl:     `nix build '.#host-pkgs.moby-cross.perl536Packages.ModuleBuild'`
# - qt:       `nix build '.#host-pkgs.moby-cross.libsForQt5.qtbase'`
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
            cantarell-fonts  # python3.10-skia-pathops
            colord  # (meson) ERROR: An exe_wrapper is needed but was not found. Please define one in cross file and check the command and/or add it to PATH.
            dante  # "configure: error: error: getaddrinfo() error value count too low"
            # duplicity  # python3.10-s3transfer
            emacs  # "configure: error: cannot run test program while cross compiling"
            flatpak  # No package 'libxml-2.0' found
            fwupd-efi  # efi/meson.build:162:0: ERROR: Program or command 'gcc' not found or not executable
            fwupd  # "Run-time dependency libgcab-1.0 found: NO (tried pkgconfig and cmake)"
            gcr_4  # meson ERROR: Program 'gpg2 gpg' not found or not executable
            gmime3  # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
            # gnome-keyring
            # gnome-remote-desktop
            # gnome-tour
            gnustep  # gnustep.base: "configure: error: Your compiler does not appear to implement the -fconstant-string-class option needed for support of strings."
            gocryptfs  # gocryptfs-2.3-go-modules
            # grpc
            gst_all_1  # (gst_all_1.gst-editing-services) `Run-time dependency gst-validate-1.0 found: NO (tried pkgconfig and cmake)`
            # gupnp_1_6  # subprojects/gi-docgen/meson.build:10:0: ERROR: python3 not found
            gvfs  # meson.build:312:2: ERROR: Assert failed: http required but libxml-2.0 not found
            # flatpak
            hdf5  # configure: error: cannot run test program while cross compiling
            # http2
            ibus  # configure.ac:152: error: possibly undefined macro: AM_PATH_GLIB_2_0
            kitty  # "FileNotFoundError: [Errno 2] No such file or directory: 'pkg-config'"
            iio-sensor-proxy  # "./autogen.sh: line 26: gtkdocize: not found"
            libgccjit  # "../../gcc-9.5.0/gcc/jit/jit-result.c:52:3: error: 'dlclose' was not declared in this scope"
            libgweather  # "Run-time dependency vapigen found: NO (tried pkgconfig)"
            libjcat  # data/tests/meson.build:10:0: ERROR: Program 'gnutls-certtool certtool' not found or not executable
            libsForQt5  # qtbase  # make: g++: No such file or directory
            mod_dnssd  # "configure: error: *** Sorry, could not find apxs ***"
            networkmanager-iodine  # configure.ac:58: error: possibly undefined macro: AM_GLIB_GNU_GETTEXT
            notmuch  # "Error: The dependencies of notmuch could not be satisfied"  (xapian, gmime, glib, talloc)
            obex_data_server  # "/nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 2: --prefix=ods_manager: command not found"
            openfortivpn  # "checking for /proc/net/route... configure: error: cannot check for file existence when cross compiling"
            ostree  # "configure: error: Need GPGME_PTHREAD version 1.1.8 or later"
            perlInterpreters  # perl5.36.0-Module-Build perl5.36.0-Test-utf8 (see tracking issues ^)
            phoc  # Program wayland-scanner found: NO
            phosh  # libadwaita-1 not found
            phosh-mobile-settings  # meson.build:26:0: ERROR: Dependency "phosh-plugins" not found, tried pkgconfig
            psqlodbc  # "configure: error: odbc_config not found (required for unixODBC build)"
            # qgnomeplatform
            # qtbase
            qt6  # error in psqlodbc, not fixed by emulating only psqlodbc above for some reason
            rapidfuzz-cpp  # error: could not find git for clone of catch2-populate
            re2  # FAILED: CMakeFiles/test.util
            rmlint  # "Checking whether the C compiler works... no"
            sequoia  # "/nix/store/q8hg17w47f9xr014g36rdc2gi8fv02qc-clang-aarch64-unknown-linux-gnu-12.0.1-lib/lib/libclang.so.12: cannot open shared object file: No such file or directory"', /build/sequoia-0.27.0-vendor.tar.gz/bindgen/src/lib.rs:1975:31"
            # splatmoji
            squeekboard  # meson.build:1:0: ERROR: 'rust' compiler binary not defined in cross or native file
            tracker-miners  # "meson.build:183:0: ERROR: Can not run test applications in this cross environment."
            twitter-color-emoji  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: pkg-config: command not found
            # unar has multiple failures:
            # - "configure: error: Your compiler does not appear to implement the -fconstant-string-class option needed for support of strings.  Please check for a more recent version or consider using --enable-nxconstantstring"
            # - "/nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: ar: command not found"
            unar
            visidata  # python3.10-psycopg2 python3.10-pandas python3.10-h5py
            # vpnc  # "/nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: perl: command not found"
            webp-pixbuf-loader  # install phase: "Builder called die: Cannot wrap '/nix/store/kpp8qhzdjqgvw73llka5gpnsj0l4jlg8-gdk-pixbuf-aarch64-unknown-linux-gnu-2.42.10/bin/gdk-pixbuf-thumbnailer' because it is not an executable file"
            # webkitgtk_4_1  # requires nativeBuildInputs = perl.pkgs.FileCopyRecursive => perl5.36.0-Test-utf8
            # xdg-desktop-portal-gnome  # data/meson.build:33:5: ERROR: Program 'msgfmt' not found or not executable
            # xdg-utils  # perl5.36.0-File-BaseDir / perl5.36.0-Module-Build
          ;

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
          cdrtools = prev.cdrtools.override {
            # "configure: error: installation or configuration problem: C compiler cc not found."
            inherit (emulated) stdenv;
          };
          # colord = prev.colord.override {
          #   # doesn't fix: "ld: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };

          # evince = prev.evince.override {
          #   # doesn't fix: "ld: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
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
          # fwupd = prev.fwupd.overrideAttrs (orig: {
          #   # solves (meson) "Run-time dependency libgcab-1.0 found: NO (tried pkgconfig and cmake)", and others.
          #   # some of these are kinda sus. maybe upstream fwupd buildscript is iffy
          #   buildInputs = orig.buildInputs ++ [ next.gcab next.gi-docgen next.gnutls next.pkg-config ];
          # });

          gmime = prev.gmime.overrideAttrs (orig: {
            # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
            configureFlags = orig.configureFlags ++ [ "ac_cv_have_iconv_detect_h=no" ];
          });
          # gmime3 = prev.gmime3.overrideAttrs (orig: {
          #   # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
          #   # unsolved: "ImportError: /nix/store/c190src4bjkfp7bdgc5sadnmvgzv7kxb-gobject-introspection-aarch64-unknown-linux-gnu-1.74.0/lib/gobject-introspection/giscanner/_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"
          #   configureFlags = orig.configureFlags ++ [ "ac_cv_have_iconv_detect_h=no" ];
          # });
          gupnp_1_6 = prev.gupnp_1_6.overrideAttrs (orig: {
            # "subprojects/gi-docgen/meson.build:10:0: ERROR: python3 not found"
            # this patch is copied from the default gupnp.
            # TODO: upstream
            outputs = [ "out" "dev" ]
              ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
            mesonFlags = [
              "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
              "-Dintrospection=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
            ];
          });

          gnome = prev.gnome.overrideScope' (self: super: {
            inherit (emulated.gnome)
              evolution-data-server  # "The 'perl' not found, not installing csv2vcard"
              gnome-keyring  # configure.ac:374: error: possibly undefined macro: AM_PATH_LIBGCRYPT
              gnome-shell  # "meson.build:128:0: ERROR: Program 'gjs' not found or not executable"
              gnome-settings-daemon  # subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable
              mutter  # meson.build:237:2: ERROR: Dependency "gbm" not found, tried pkgconfig  (it's provided by mesa)
            ;
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
            # gnome-settings-daemon = super.gnome-settings-daemon.overrideAttrs (orig: {
            #   # fixes "subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable"
            #   # new error: "plugins/power/meson.build:22:0: ERROR: Dependency lookup for glib-2.0 with method 'pkgconfig' failed: Pkg-config binary for machine 0 not found. Giving up."
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            # });
            gnome-session = super.gnome-session.overrideAttrs (orig: {
              # fixes: "gdbus-codegen not found or executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            gnome-user-share = super.gnome-user-share.overrideAttrs (orig: {
              # fixes: meson.build:111:6: ERROR: Program 'glib-compile-schemas' not found or not executable
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # mutter = super.mutter.override {
            #   # DOES NOT FIX: "meson.build:237:2: ERROR: Dependency "gbm" not found, tried pkgconfig  (it's provided by mesa)"
            #   inherit (next) stdenv;
            # };
          });

          # gst_all_1.gst-editing-services = emulated.gst_all_1.gst-editing-services;
          # gst_all_1 = prev.gst_all_1.overrideScope' (self: super: {
          #   inherit (emulated.gst_all_1)
          #     gst-editing-services
          #   ;
          # });
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

          # ibus = prev.ibus.override {
          #   # "_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"
          #   inherit (emulated) stdenv;
          # };

          libHX = prev.libHX.overrideAttrs (orig: {
            # "Can't exec "libtoolize": No such file or directory at /nix/store/r4fvx9hazsm0rdm7s393zd5v665dsh1c-autoconf-2.71/share/autoconf/Autom4te/FileUtils.pm line 294."
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.libtool ];
          });

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
          # libsForQt5 = prev.libsForQt5.overrideScope' (self: super: {
          #   inherit (emulated.libsForQt5)
          #     qtbase
          #   ;
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
            nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.glib ];
          });
          # networkmanager-iodine = prev.networkmanager-iodine.overrideAttrs (orig: {
          #   # fails to fix "configure.ac:58: error: possibly undefined macro: AM_GLIB_GNU_GETTEXT"
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.gettext ];
          # });
          networkmanager-l2tp = prev.networkmanager-l2tp.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            # fixes "gtk4-builder-tool: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.glib prev.gtk4 ];
          });
          networkmanager-openconnect = prev.networkmanager-openconnect.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.glib ];
          });
          networkmanager-openvpn = prev.networkmanager-openvpn.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.glib ];
          });
          networkmanager-sstp = prev.networkmanager-sstp.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.glib ];
          });
          networkmanager-vpnc = prev.networkmanager-vpnc.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.glib ];
          });
          nheko = prev.nheko.overrideAttrs (orig: {
            # fixes "fatal error: lmdb++.h: No such file or directory
            buildInputs = orig.buildInputs ++ [ next.lmdbxx ];
          });

          pam_mount = prev.pam_mount.overrideAttrs (orig: {
            # fixes: "perl: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.perl ];
          });

          # perlPackageOverrides = _perl: {
          #   inherit (pkgs.emulated.perl.pkgs)
          #     Testutf8
          #   ;
          # };

          pipewire = prev.pipewire.overrideAttrs (orig: {
            # fix `spa/plugins/bluez5/meson.build:41:0: ERROR: Program 'gdbus-codegen' not found or not executable`
            nativeBuildInputs = orig.nativeBuildInputs ++ [ prev.glib ];
          });

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
              # skia-pathops
              #   it tries to call `cc` during the build, but can't find it.
            })
          ];
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

          # unar = (prev.unar.override {
          #   # fixes "ar: command not found"
          #   # new error: "gcc: error: unrecognized command line option '-fobjc-runtime=gnustep-2.0'"
          #   inherit (emulated) stdenv;
          # });

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
      })
    ];
  };
}
