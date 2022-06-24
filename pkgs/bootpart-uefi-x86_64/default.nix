{ stdenv, pkgs }:

stdenv.mkDerivation rec {
  pname = "bootpart-uefi-x86_64";
  version = "1";

  buildInputs = [ pkgs.syslinux ];

  dontUnpack = true;

  installPhase = with pkgs; ''
    # populate the EFI directory with syslinux, and configure it to read that extlinux.conf file managed by nixos
    mkdir -p "$out/EFI/syslinux"  "$out/EFI/BOOT"
    cp -R "${syslinux}/share/syslinux/efi64"/* "$out/EFI/syslinux"
    echo "DEFAULT trampoline" > "$out/EFI/syslinux/syslinux.cfg"
    echo "LABEL trampoline" >> "$out/EFI/syslinux/syslinux.cfg"
    echo "CONFIG ../../extlinux/extlinux.conf ../../extlinux" >> "$out/EFI/syslinux/syslinux.cfg"
    
    # create the EFI/BOOT/BOOTX64.EFI default entry
    cp "$out/EFI/syslinux"/* "$out/EFI/BOOT"
    mv "$out/EFI/BOOT/syslinux.efi" "$out/EFI/BOOT/BOOTX64.EFI"
  '';


  meta = {
    description = "unmanaged files to place in /boot on a x86-64 extlinux system";
    platforms = [ "x86_64-linux" ];
  };
}

