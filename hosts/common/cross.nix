# cross compiling
# - for edge-casey things (e.g. `mesonEmulatorHook`, `depsBuildBuild`), see in nixpkgs:
#   `git show da9a9a440415b236f22f57ba67a24ab3fb53f595`

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
            appstream
            blueman
            brltty
            cantarell-fonts  # python3.10-skia-pathops
            cdrtools
            colord
            # duplicity  # python3.10-s3transfer
            evince
            flakpak
            fuzzel
            fwupd-efi
            fwupd
            gcr_4  # meson ERROR: Program 'gpg2 gpg' not found or not executable
            gmime
            # gnome-keyring
            # gnome-remote-desktop
            # gnome-tour
            gnustep  # (gnustep.base is used by unar; can't override individual members)
            gocryptfs  # gocryptfs-2.3-go-modules
            # grpc
            gst_all_1  # gst_all_1.gst-editing-services
            gupnp
            gupnp_1_6
            # gvfs  # meson.build:312:2: ERROR: Assert failed: http required but libxml-2.0 not found
            flatpak
            hdf5  # configure: error: cannot run test program while cross compiling
            http2
            ibus
            kitty
            iio-sensor-proxy
            libHX
            libgweather
            librest
            librest_1_0
            libsForQt5  # qtbase
            libuv
            mod_dnssd
            ncftp
            obex_data_server
            openfortivpn
            ostree
            pam_mount
            perl  # perl5.36.0-Test-utf8
            # pipewire
            psqlodbc
            # pulseaudio  # python3.10-defcon
            # qgnomeplatform
            # qtbase
            qt6  # psqlodbc
            rmlint
            sequoia
            # splatmoji
            squeekboard
            sysprof
            tracker-miners  # it just can't run tests
            # twitter-color-emoji  # python3.10-defcon
            unar  # meson.build:52:2: ERROR: Program 'gpg2 gpg' not found or not executable
            visidata  # python3.10-psycopg2 python3.10-pandas python3.10-h5py
            vpnc
            webp-pixbuf-loader
            xdg-utils  # perl5.36.0-File-BaseDir
          ;
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
                # TODO: upstream
                # - see: <https://github.com/NixOS/nixpkgs/issues/210265>
                # """
                #   i was able to just add `postgresql` to the `buildInputs`  (so that it's in both `buildInputs` and `nativeBuildInputs`):
                #   it fixed the build for `pkgsCross.aarch64-multiplatform.python310Packages.psycopg2` but not for `armv7l-hf-multiplatform` that this issue description calls out.
                #
                #   also i haven't deployed it yet to make sure this doesn't cause anything funky at runtime though.
                # """
                #
                # psycopg2 *links* against libpg, so we need the host postgres available at build time!
                # present-day nixpkgs only includes it in nativeBuildInputs
                buildInputs = orig.buildInputs ++ [ next.postgresql ];
              });
              s3transfer = py-prev.s3transfer.overridePythonAttrs (orig: {
                # TODO: this doesn't actually stop the unit tests from running!
                # some (or all?) tests fail if the test runner isn't on the same platform as the host (?)
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

          gnome = prev.gnome.overrideScope' (self: super: {
            inherit (emulated.gnome)
              gnome-color-manager
              gnome-keyring
              # gnome-remote-desktop
              gnome-settings-daemon  # subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable
              gnome-user-share
              mutter
            ;
          });

          # gst_all_1.gst-editing-services = emulated.gst_all_1.gst-editing-services;

          # gst_all_1 = prev.gst_all_1.overrideScope' (self: super: {
          #   inherit (emulated.gst_all_1)
          #     gst-editing-services
          #   ;
          # });

          # libsForQt5 = prev.libsForQt5.overrideScope' (self: super: {
          #   inherit (emulated.libsForQt5)
          #     qtbase
          #   ;
          # });

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
      })
    ];

    # perlPackageOverrides = _perl: {
    #   inherit (pkgs.emulated.perl.pkgs)
    #     Testutf8
    #   ;
    # };
  };
}
