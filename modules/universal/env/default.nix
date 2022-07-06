{ ... }:

{
  imports = [
    ./users.nix
    ./home-manager.nix
  ];

  # programs.vim.defaultEditor = true;
  environment.variables = {
    EDITOR = "vim";
    # git claims it should use EDITOR, but it doesn't!
    GIT_EDITOR = "vim";
  };
}

