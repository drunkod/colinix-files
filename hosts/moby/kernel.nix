{ lib, pkgs, ... }:
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

  # the idea for patching off Manjaro's kernel comes from jakewaksbaum:
  # - https://git.sr.ht/~jakewaksbaum/pi/tree/af20aae5653545d6e67a459b59ee3e1ca8a680b0/item/kernel/default.nix
  # - he later abandoned this, i think because he's using the Pinephone Pro which received mainline support.
  manjaroPatches = [
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
  ];

  # pinephone uses the linux dtb at arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone.dtsi
  # - this includes sun50i-a64.dtsi
  # - and sun50i-a64-cpu-opp.dtsi
  # - no need to touch the allwinner-h6 stuff: that's the SBC pine product
  # - i think it's safe to ignore sun9i stuff, but i don't know what it is
  kernelConfig = with lib.kernel; {
    # NB: nix adds the CONFIG_ prefix to each of these.
    # if you add the prefix yourself nix will IGNORE YOUR CONFIG.
    RTL8723CS = module;
    BT_HCIUART_3WIRE = yes;
    BT_HCIUART_RTL = yes;
    RTL8XXXU_UNTESTED = yes;
    BT_BNEP_MC_FILTER = yes;
    BT_BNEP_PROTO_FILTER = yes;
    BT_HS = yes;
    BT_LE = yes;
    # relevant configs inherited from nixos defaults (or above additions):
    # CONFIG_BT=m
    # CONFIG_BT_BREDR=y
    # CONFIG_BT_RFCOMM=m
    # CONFIG_BT_RFCOMM_TTY=y
    # CONFIG_BT_BNEP=m
    # CONFIG_BT_HIDP=m
    # CONFIG_BT_RTL=m
    # CONFIG_BT_HCIBTUSB=m
    # CONFIG_BT_HCIBTUSB_BCM=y
    # CONFIG_BT_HCIBTUSB_RTL=y
    # CONFIG_BT_HCIUART=m
    # CONFIG_BT_HCIUART_SERDEV=y
    # CONFIG_BT_HCIUART_H4=y
    # CONFIG_BT_HCIUART_LL=y
    # CONFIG_RTL_CARDS=m
    # CONFIG_RTLWIFI=m
    # CONFIG_RTLWIFI_PCI=m
    # CONFIG_RTLWIFI_USB=m
    # CONFIG_RTLWIFI_DEBUG=y
    # CONFIG_RTL8723_COMMON=m
    # CONFIG_RTLBTCOEXIST=m
    # CONFIG_RTL8XXXU=m
    # CONFIG_RTLLIB=m
    # consider adding (from mobile-nixos):
    # maybe: CONFIG_BT_HCIUART_3WIRE=y
    # maybe: CONFIG_BT_HCIUART_RTL=y
    # maybe: CONFIG_RTL8XXXU_UNTESTED=y
    # consider adding (from manjaro):
    # CONFIG_BT_6LOWPAN=m  (not listed as option in nixos kernel)
    # these are referenced in the rtl8723 source, but not known to config (and not in mobile-nixos config
    # maybe: CONFIG_RTL_ODM_WLAN_DRIVER
    # maybe: CONFIG_RTL_TRIBAND_SUPPORT
    # maybe: CONFIG_SDIO_HCI
    # maybe: CONFIG_USB_HCI
  };

  # create a kernelPatch which overrides nixos' defconfig with extra options
  patchDefconfig = config: {
    # defconfig options. this method comes from here:
    # - https://discourse.nixos.org/t/the-correct-way-to-override-the-latest-kernel-config/533/9
    name = "sane-moby-defconfig";
    patch = null;
    extraStructuredConfig = config;
  };
in
{
  # use Megi's kernel:
  # even with the Manjaro patches, stock 5.18 has a few issues on Pinephone:
  # - no battery charging
  # - phone rotation sensor is off by 90 degrees
  # - ambient light sensor causes screen brightness to be shakey
  # - phosh greeter may not appear after wake from sleep
  boot.kernelPackages = pkgs.cross.linuxPackagesFor pkgs.cross.linux-megous;

  boot.kernelPatches = [
    (patchDefconfig (kernelConfig //
      (with lib.kernel; {
        # disabling the sun5i_eink driver avoids this compilation error:
        # CC [M]  drivers/video/fbdev/sun5i-eink-neon.o
        # aarch64-unknown-linux-gnu-gcc: error: unrecognized command line option '-mfloat-abi=softfp'
        # aarch64-unknown-linux-gnu-gcc: error: unrecognized command line option '-mfpu=neon'
        # make[3]: *** [../scripts/Makefile.build:289: drivers/video/fbdev/sun5i-eink-neon.o] Error 1
        FB_SUN5I_EINK = no;
        # used by the pinephone pro, but fails to compile with:
        # ../drivers/media/i2c/ov8858.c:1834:27: error: implicit declaration of function 'compat_ptr'
        VIDEO_OV8858 = no;
      })
    ))
  ];

  # alternatively, use nixos' kernel and add the stuff we want:
  # # cross-compilation optimization:
  # boot.kernelPackages =
  #   let p = (import nixpkgs { localSystem = "x86_64-linux"; });
  #   in p.pkgsCross.aarch64-multiplatform.linuxPackages_5_18;
  # # non-cross:
  # # boot.kernelPackages = pkgs.linuxPackages_5_18;

  # boot.kernelPatches = manjaroPatches ++ [
  #   (patchDefconfig kernelConfig)
  # ];
}
