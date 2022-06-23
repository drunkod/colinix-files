{ config, pkgs, ... }:
{
  system.build.img = pkgs.runCommandNoCC "nixos_full-disk-image.img" {} ''
    cp -v ${config.system.build.img-without-firmware}/nixos.img $out
    chmod +w $out
    dd if=${pkgs.tow-boot-pinephone}/Tow-Boot.noenv.bin of=$out bs=1024 seek=8 conv=notrunc
  '';
}
