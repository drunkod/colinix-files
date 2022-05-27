{ ... }:

{
  imports = [
    ./home-manager.nix
    ./users.nix
  ];

  time.timeZone = "America/Los_Angeles";
}

