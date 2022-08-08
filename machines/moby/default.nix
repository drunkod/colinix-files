{ config, pkgs, lib, mobile-nixos, ... }:
{
  imports = [
    # (import "${mobile-nixos}/lib/configuration.nix" {
    #   device = "pine64-pinephone";
    # })
    ./firmware.nix
    ./fs.nix
  ];
  # nixpkgs.overlays = [(next: prev: {
  #   # without this, kernel module build fails due to lacking dm_mod.
  #   # see: https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
  #   # dm_mod appears to still be loaded, though? maybe some weird thing between compiled and dynamically-loaded mods?
  #   makeModulesClosure = x:
  #     prev.makeModulesClosure (x // { allowMissing = true; });
  # })];
  # XXX colin: phosh doesn't work well with passwordless login
  users.users.colin.initialPassword = "147147";
  services.getty.autologinUser = "root";  # allows for emergency maintenance?

  # usability compromises
  sane.impermanence.home-dirs = [
    ".librewolf"
  ];

  # sane.home-manager.extraPackages = [
  #   # for web browsers see: https://forum.pine64.org/showthread.php?tid=13669
  #   pkgs.angelfish  # plasma mobile web browser; broken on phosh (poor wayland support)
  #   # pkgs.plasma5Packages.index  # file browser
  #   pkgs.plasma5Packages.konsole  # terminal
  #   # pkgs.plasma5Packages.pix  # picture viewer
  #   pkgs.plasma5Packages.kalk  # calculator; broken on phosh
  #   # pkgs.plasma5Packages.buho  # (plasma mobile?) note application
  #   pkgs.plasma5Packages.kasts  #  podcast app; works on phosh after setting QT envar
  #   pkgs.plasma5Packages.koko  # image gallery; broken on phosh
  #   pkgs.plasma5Packages.kwave  # media player.
  #   # pkgs.plasma5Packages.neochat  #  matrix client. needs qcoro => no aarch64 support
  #   # pkgs.plasma5Packages.plasma-dialer  # phone dialer
  #   # pkgs.plasma5Packages.plasma-mobile  # the whole shebang?
  #   # pkgs.plasma5Packages.plasma-settings
  #   pkgs.plasma5Packages.bomber  # arcade game; broken on phosh
  #   pkgs.plasma5Packages.kapman  # pacman
  #   pkgs.st  # suckless terminal; broken on phosh
  #   # pkgs.alacritty  # terminal; crashes phosh
  # ];
  # sane.home-packages.enableGuiPkgs = false;  # XXX faster builds/imaging for debugging
  sane.home-manager.extraPackages = [
    pkgs.plasma5Packages.konsole  # terminal
  ];

  sane.nixcache.enable = true;
  sane.impermanence.enable = true;
  sane.gui.phosh.enable = true;

  # pinephone uses the linux dtb at arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone.dtsi
  # - this includes sun50i-a64.dtsi
  # - and sun50i-a64-cpu-opp.dtsi
  # - no need to touch the allwinner-h6 stuff: that's the SBC pine product
  # - i think it's safe to ignore sun9i stuff, but i don't know what it is
  boot.kernelPackages = pkgs.linuxPackages_5_18;
  boot.kernelPatches =
  let
    # use the last commit on the 5.18 branch (5.18.14)
    # manjaro's changes between kernel patch versions tend to be minimal if any.
    manjaroBase = "https://gitlab.manjaro.org/manjaro-arm/packages/core/linux/-/raw/25bd828cd47b1c6e09fcbcf394a649b89d2876dd";
    manjaroPatch = name: sha256: {
      inherit name;
      patch = pkgs.fetchpatch {
        inherit name;
	url = "${manjaroBase}/${name}?inline=false";
	inherit sha256;
      };
    };
  in [
    # the idea for patching off Manjaro's kernel comes from jakewaksbaum:
    # - https://git.sr.ht/~jakewaksbaum/pi/tree/af20aae5653545d6e67a459b59ee3e1ca8a680b0/item/kernel/default.nix
    # - he later abandoned this, i think because he's using the Pinephone Pro which received mainline support.
    (manjaroPatch
      "1001-arm64-dts-allwinner-add-hdmi-sound-to-pine-devices.patch"
      "sha256-DApd791A+AxB28Ven/MVAyuyVphdo8KQDx8O7oxVPnc="
    )
    # these patches below are critical to enable wifi (RTL8723CS)
    # - the alternative is a wholly forked kernel by megi/megous:
    #   - https://xnux.eu/howtos/build-pinephone-kernel.html#toc-how-to-build-megi-s-pinehpone-kernel
    # - i don't know if these patches are based on megi's or original
    (manjaroPatch
      "2001-Bluetooth-Add-new-quirk-for-broken-local-ext-features.patch"
      "sha256-CExhJuUWivegxPdnzKINEsKrMFx/m/1kOZFmlZ2SEOc="
    )
    (manjaroPatch
      "2002-Bluetooth-btrtl-add-support-for-the-RTL8723CS.patch"
      "sha256-dDdvOphTcP/Aog93HyH+L9m55laTgtjndPSE4/rnzUA="
    )
    (manjaroPatch
      "2004-arm64-dts-allwinner-enable-bluetooth-pinetab-pinepho.patch"
      "sha256-o43P3WzXyHK1PF+Kdter4asuyGAEKO6wf5ixcco2kCQ="
    )
    # XXX: this one has a Makefile, which hardcodes /sbin/depmod:
    # - drivers/staging/rtl8723cs/Makefile
    # - not sure if this is problematic?
    (manjaroPatch
      "2005-staging-add-rtl8723cs-driver.patch"
      "sha256-6ywm3dQQ5JYl60CLKarxlSUukwi4QzqctCj3tVgzFbo="
    )
    {
      # defconfig options. this method comes from here:
      # - https://discourse.nixos.org/t/the-correct-way-to-override-the-latest-kernel-config/533/9
      name = "sane-moby-defconfig";
      patch = null;
      extraStructuredConfig = with lib.kernel; {
        CONFIG_RTL8723CS = module;
        # maybe: CONFIG_RTL_ODM_WLAN_DRIVER
        # maybe: CONFIG_RTL_TRIBAND_SUPPORT
        # maybe: CONFIG_SDIO_HCI
        # maybe: CONFIG_USB_HCI
        # maybe: CONFIG_RTL8XXXU=m
        # maybe: CONFIG_RTL8XXXU_UNTESTED=y
      };
    }
  ];

  boot.loader.efi.canTouchEfiVariables = false;
  # mobile.bootloader.enable = false;
  # mobile.boot.stage-1.enable = false;
  # boot.initrd.systemd.enable = false;
  # boot.initrd.services.swraid.enable = false;  # attempt to fix dm_mod stuff

  # mobile-nixos' /lib/firmware includes:
  #   rtl_bt          (bluetooth)
  #   anx7688-fw.bin  (USB-C -> HDMI bridge)
  #   ov5640_af.bin   (camera module)
  # hardware.firmware = [ config.mobile.device.firmware ];

  system.stateVersion = "21.11";

  # defined: https://www.freedesktop.org/software/systemd/man/machine-info.html
  # XXX colin: not sure which, if any, software makes use of this
  environment.etc."machine-info".text = ''
    CHASSIS="handset"
  '';

  # enable rotation sensor
  hardware.sensor.iio.enable = true;

  users.groups.feedbackd.gid = config.sane.allocations.feedbackd-gid;
}
