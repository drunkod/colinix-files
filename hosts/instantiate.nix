# trampoline from flake.nix into the specific host definition, while doing a tiny bit of common setup

hostName: { ... }: {
  imports = [
    ./${hostName}
  ];

  networking.hostName = hostName;

  nixpkgs.config.allowUnfree = true;
}
