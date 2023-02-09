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
      (next: prev: rec {
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
            apacheHttpd  # TODO: not properly patched  (we only need mod_dnssd?)
            appstream  # meson.build:139:0: ERROR: Program 'gperf' not found or not executable
            cantarell-fonts  # python3.10-skia-pathops
            colord  # (meson) ERROR: An exe_wrapper is needed but was not found. Please define one in cross file and check the command and/or add it to PATH.
            # duplicity  # python3.10-s3transfer
            evince  # "Run-time dependency gi-docgen found: NO (tried pkgconfig and cmake)"
            fwupd-efi  # efi/meson.build:162:0: ERROR: Program or command 'gcc' not found or not executable
            fwupd  # "Run-time dependency libgcab-1.0 found: NO (tried pkgconfig and cmake)"
            gcr_4  # meson ERROR: Program 'gpg2 gpg' not found or not executable
            # gnome-keyring
            # gnome-remote-desktop
            # gnome-tour
            gnustep  # gnustep.base: "configure: error: Your compiler does not appear to implement the -fconstant-string-class option needed for support of strings."
            gocryptfs  # gocryptfs-2.3-go-modules
            # grpc
            gst_all_1  # gst_all_1.gst-editing-services
            # gupnp_1_6  # subprojects/gi-docgen/meson.build:10:0: ERROR: python3 not found
            gvfs  # meson.build:312:2: ERROR: Assert failed: http required but libxml-2.0 not found
            # flatpak
            hdf5  # configure: error: cannot run test program while cross compiling
            # http2
            ibus  # configure.ac:152: error: possibly undefined macro: AM_PATH_GLIB_2_0
            kitty
            iio-sensor-proxy
            libgweather
            libHX
            libjcat  # data/tests/meson.build:10:0: ERROR: Program 'gnutls-certtool certtool' not found or not executable
            # TODO: librest*: disable doc building with --disable-gtk-doc
            librest  # You must have gtk-doc >= 1.13 installed to build documentation
            librest_1_0  # (meson) Run-time dependency gi-docgen found: NO (tried pkgconfig and cmake)
            libsForQt5  # qtbase  # make: g++: No such file or directory
            # libuv
            mod_dnssd
            ncftp
            networkmanager-fortisslvpn  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 2: gdbus-codegen: command not found
            networkmanager-iodine  # configure.ac:58: error: possibly undefined macro: AM_GLIB_GNU_GETTEXT
            networkmanager-l2tp  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 2: gdbus-codegen: command not found
            networkmanager-openconnect  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: properties/gresource.xml: Permission denied
            networkmanager-openvpn  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: properties/gresource.xml: Permission denied
            networkmanager-sstp  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 2: gdbus-codegen: command not found
            networkmanager-vpnc  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: properties/gresource.xml: Permission denied
            obex_data_server
            openfortivpn
            ostree
            pam_mount
            perlInterpreters  # perl5.36.0-Module-Build perl5.36.0-Test-utf8 (see tracking issues ^)
            phoc  # Program wayland-scanner found: NO
            # pipewire
            # psqlodbc
            pulseaudio  # FAILED: meson-internal__test
            # qgnomeplatform
            # qtbase
            qt6  # psqlodbc
            re2  # FAILED: CMakeFiles/test.util
            rmlint
            sequoia
            # splatmoji
            squeekboard  # meson.build:1:0: ERROR: 'rust' compiler binary not defined in cross or native file
            sysprof
            tpm2-abrmd  # configure: error: *** gdbus-codegen is required to build tpm2-abrmd; No package 'gio-unix-2.0' found
            tracker-miners  # it just can't run tests
            twitter-color-emoji  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: pkg-config: command not found
            # unar has multiple failures:
            # - "configure: error: Your compiler does not appear to implement the -fconstant-string-class option needed for support of strings.  Please check for a more recent version or consider using --enable-nxconstantstring"
            # - "/nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: ar: command not found"
            unar
            visidata  # python3.10-psycopg2 python3.10-pandas python3.10-h5py
            vpnc
            webp-pixbuf-loader
            # webkitgtk_4_1  # requires nativeBuildInputs = perl.pkgs.FileCopyRecursive => perl5.36.0-Test-utf8
            xdg-desktop-portal-gtk  # No package 'xdg-desktop-portal' found
            xdg-desktop-portal-gnome  # data/meson.build:33:5: ERROR: Program 'msgfmt' not found or not executable
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

          blueman = prev.blueman.overrideAttrs(orig: {
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
              evolution-data-server  # 'nix log /nix/store/ghlsq1jl5js5jiy24b4p1k67k4sgrnv7-libuv-1.44.2.drv'
              gnome-color-manager
              gnome-control-center  # subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable
              gnome-keyring
              # TODO: remove gnome-remote-desktop (wanted by gnome-control-center)
              gnome-remote-desktop  # Program gdbus-codegen found: NO
              gnome-settings-daemon  # subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable
              gnome-user-share
              mutter  # meson.build:237:2: ERROR: Dependency "gbm" not found, tried pkgconfig  (it's provided by mesa)
            ;
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

          # librest = prev.librest.overrideAttrs (orig: {
          #  # You must have gtk-doc >= 1.13 installed to build documentation  (TODO: add '--disable-gtk-doc')
          #   inherit (emulated) stdenv;
          # });
          # librest_1_0 = prev.librest_1_0.overrideAttrs (orig: {
          #   # Run-time dependency gi-docgen found: NO (tried pkgconfig and cmake)
          #   inherit (emulated) stdenv;
          # });
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

          # unar = (prev.unar.override {
          #   # "meson.build:52:2: ERROR: Program 'gpg2 gpg' not found or not executable"
          #   inherit (emulated) stdenv;
          # }).overrideAttrs (orig: {
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.coreutils-full ];
          # });
      })
    ];
  };
}
