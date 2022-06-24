{ config, pkgs, ... }:
{
  # we need space in the GPT header to place tow-boot.
  # only actually need 1 MB, but better to over-allocate than under-allocate
  colinsane.image.extraGPTPadding = 16 * 1024 * 1024;
  system.build.img = pkgs.runCommandNoCC "nixos_full-disk-image.img" {} ''
    cp -v ${config.system.build.img-without-firmware}/nixos.img $out
    chmod +w $out
    dd if=${pkgs.tow-boot-pinephone}/Tow-Boot.noenv.bin of=$out bs=1024 seek=8 conv=notrunc
  '';
}
