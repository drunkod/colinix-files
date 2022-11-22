# trampoline from flake.nix into the specific host definition, while doing a tiny bit of common setup

hostName: { ... }: {
  imports = [
    ./${hostName}
    ./common
  ];

  networking.hostName = hostName;
}
