#! @bash@/bin/sh -ex

# this wraps <nixpkgs>/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.sh
# to expose a COMPLETE extlinux bootloader installation.

# parse CLI. we only care about some of the flags
target=/boot # default target
while getopts "t:c:d:g:n:r" opt; do
    case "$opt" in
        d) target="$OPTARG" ;;
        *) ;;
    esac
done

# populate /boot/extlinux/extlinux.conf & /boot/nixos
@genericBuilder@ $@

# populate the EFI directory with syslinux, and configure it to read that extlinux.conf file managed by nixos
mkdir -p $target/EFI/syslinux
cp @syslinux@/share/syslinux/efi64/* $target/EFI/syslinux/
echo "DEFAULT trampoline" > $target/EFI/syslinux/syslinux.cfg
echo "LABEL trampoline" >> $target/EFI/syslinux/syslinux.cfg
echo "CONFIG ../../extlinux/extlinux.conf ../../extlinux" >> $target/EFI/syslinux/syslinux.cfg

# create the EFI/BOOT/BOOTX64.EFI default entry
cp -R $target/EFI/syslinux $target/EFI/BOOT
mv $target/EFI/BOOT/syslinux.efi $target/EFI/BOOT/BOOTX64.EFI
