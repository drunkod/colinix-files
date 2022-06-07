{ ... }:

{
  imports = [
    ./fs.nix
    ./home-manager.nix
    ./nix-cache.nix
    ./secrets.nix
    ./users.nix
  ];

  time.timeZone = "America/Los_Angeles";

  # programs.vim.defaultEditor = true;
  environment.variables = {
    EDITOR = "vim";
    # git claims it should use EDITOR, but it doesn't!
    GIT_EDITOR = "vim";
  };
}

