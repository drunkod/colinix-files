# trampoline from flake.nix into the specific machine definition, while doing a tiny bit of common setup

hostName: { ... }: {
  imports = [
    ./${hostName}
  ];

  networking.hostName = hostName;

  nixpkgs.config.allowUnfree = true;
}
