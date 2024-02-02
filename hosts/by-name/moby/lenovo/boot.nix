  { config, pkgs, ... }:
{
    # Bootloader
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.forcei686 = true;

  sane.root-on-tmpfs = false;
  
}