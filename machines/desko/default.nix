{ home-manager, config, pkgs, ... }:
{
  imports = [
    ./../common/homes.nix
    ./../common/users.nix
    ./../common/hardware.nix
    ./../common/gui.nix
    ./fs.nix
  ];

  home-manager.users.colin = import ./../../helpers/home-manager-gen-colin.nix {
    inherit pkgs; system = "x86_64-linux"; gui = "gnome";
  };
}
