{ pkgs, ... }:
{
  sane.programs = {
    btrfs-progs.enableFor.system = true;
    # "cacert.unbundled".enableFor.system = true;
    cryptsetup.enableFor.system = true;
    dig = {
      enableFor.system = true;
      suggestedPrograms = [ "efibootmgr" ];
    };
    efibootmgr = {};
    fatresize = {};

    backblaze-b2.enableFor.user.colin = true;
    cdrtools = {
      enableFor.user.colin = true;
      suggestedPrograms = [ "dmidecode" ];
    };
    dmidecode = {};
  };
}
