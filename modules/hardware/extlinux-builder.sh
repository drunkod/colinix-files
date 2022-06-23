#! @bash@/bin/sh -ex
# populate /boot/extlinux/extlinux.conf & /boot/nixos
@genericBuilder@ $@

# populate the EFI directory with syslinux, and configure it to read that extlinux.conf file managed by nixos
# TODO: read output directory
mkdir -p ./EFI/syslinux
cp @syslinux@/share/syslinux/efi64/* ./EFI/syslinux/
echo "DEFAULT trampoline" > ./EFI/syslinux/syslinux.cfg
echo "LABEL trampoline" >> ./EFI/syslinux/syslinux.cfg
echo "CONFIG ../../extlinux/extlinux.conf ../../extlinux" >> ./EFI/syslinux/syslinux.cfg

# create the EFI/BOOT/BOOTX64.EFI default entry
cp -R ./EFI/syslinux ./EFI/BOOT
mv ./EFI/BOOT/syslinux.efi ./EFI/BOOT/BOOTX64.EFI
