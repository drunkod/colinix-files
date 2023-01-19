{ pkgs, ... }:

{
  imports = [
    ./fs.nix
    ./net.nix
    ./users.nix
    ./secrets.nix
    ./services
  ];

  sane.packages.extraUserPkgs = with pkgs; [
    # for administering services
    freshrss
    matrix-synapse
    signaldctl
  ];
  sane.persist.enable = true;
  sane.services.dyn-dns.enable = true;
  # sane.services.duplicity.enable = true;  # TODO: re-enable after HW upgrade

  boot.loader.efi.canTouchEfiVariables = false;
  sane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  # both transmission and ipfs try to set different net defaults.
  # we just use the most aggressive of the two here:
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 4194304;  # 4MB
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11";
}

