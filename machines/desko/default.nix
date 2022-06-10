{ pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  colinsane.home-manager.extraPackages = [
    pkgs.electron
  ];
  colinsane.gui.sway.enable = true;
  colinsane.services.duplicity.enable = true;

  sops.secrets.duplicity_passphrase = {
    sopsFile = ../../secrets/desko.yaml;
  };

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
