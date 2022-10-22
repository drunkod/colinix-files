{ ... }:
{
  sane.impermanence.home-files = [ ".zsh_history" ];
  home-manager.users.colin.programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
    enableVteIntegration = true;
    history.ignorePatterns = [ "rm *" ];
    # history.path = TODO
    dotDir = ".config/zsh";

    initExtraBeforeCompInit = ''
      # p10k instant prompt
      # run p10k configure to configure, but it can't write out its file :-(
      POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
    '';
    initExtra = ''
      # zmv is a way to do rich moves/renames, with pattern matching/substitution.
      # see for an example: <https://filipe.kiss.ink/zmv-zsh-rename/>
      autoload -Uz zmv

      function nd() {
        mkdir -p "$1";
        pushd "$1";
      }
    '';

    # prezto = oh-my-zsh fork; controls prompt, auto-completion, etc.
    # see: https://github.com/sorin-ionescu/prezto
    prezto = {
      enable = true;
      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "spectrum"
        "utility"
        "completion"
        "prompt"
        "git"
      ];
      prompt = {
        theme = "powerlevel10k";
      };
    };
  };

  home-manager.users.colin.home.shellAliases = {
    ":q" = "exit";
    # common typos
    "cd.." = "cd ..";
    "cd../" = "cd ../";
  };
}
