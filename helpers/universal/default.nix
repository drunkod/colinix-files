{ ... }:

{
  imports = [
    ./fs.nix
    ./home-manager.nix
    ./nix-cache.nix
    ./users.nix
  ];

  time.timeZone = "America/Los_Angeles";

  environment.variables = {
    EDITOR = "vim";
  };
}

