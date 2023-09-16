# zsh files/init order
# - see `man zsh` => "STARTUP/SHUTDOWN FILES"
# - /etc/zshenv
# - $ZDOTDIR/.zshenv
# - if login shell:
#   - /etc/zprofile
#   - $ZDOTDIR/.zprofile
# - if interactive:
#   - /etc/zshrc
#     -> /etc/zinputrc
#   - $ZDOTDIR/.zshrc
# - if login (again):
#   - /etc/zlogin
#   - ZDOTDIR/.zlogin
# - at exit:
#   - $ZDOTDIR/.zlogout
#   - /etc/zlogout

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.sane.zsh;
in
{
  imports = [
    ./starship.nix
  ];
  options = {
    sane.zsh = {
      showDeadlines = mkOption {
        type = types.bool;
        default = true;
        description = "show upcoming deadlines (from my PKM) upon shell init";
      };
      starship = mkOption {
        type = types.bool;
        default = true;
        description = "enable starship prompt";
      };
    };
  };

  config = mkMerge [
    ({
      sane.programs.zsh = {
        persist.private = [
          # we don't need to full zsh dir -- just the history file --
          # but zsh will sometimes backup the history file and symlinking just the file messes things up
          ".local/share/zsh"
        ];

        fs.".config/zsh/.zshrc".symlink.text = ''
          # zsh/prezto complains if zshrc doesn't exist or is empty;
          # preserve this comment to prevent that from ever happening.
        '' + lib.optionalString cfg.showDeadlines ''
          ${pkgs.sane-scripts.deadlines}/bin/sane-deadlines
        '' + ''

          HISTFILE="$HOME/.local/share/zsh/history"

          # auto-cd into any of these dirs by typing them and pressing 'enter':
          hash -d 3rd="/home/colin/dev/3rd"
          hash -d dev="/home/colin/dev"
          hash -d knowledge="/home/colin/knowledge"
          hash -d nixos="/home/colin/nixos"
          hash -d nixpkgs="/home/colin/dev/3rd/nixpkgs"
          hash -d ref="/home/colin/ref"
          hash -d secrets="/home/colin/knowledge/secrets"
          hash -d tmp="/home/colin/tmp"
          hash -d uninsane="/home/colin/dev/uninsane"
          hash -d Videos="/home/colin/Videos"

          # emulate bash keybindings
          bindkey -e

          # or manually recreate what i care about...
          # key[Left]=''${terminfo[kcub1]}
          # key[Right]=''${terminfo[kcuf1]}
          # bindkey '^R'               history-incremental-search-backward
          # bindkey '^A'               beginning-of-line
          # bindkey '^E'               end-of-line
          # bindkey "^''${key[Left]}"  backward-word
          # bindkey "^''${key[Right]}" forward-word
        '';
      };
    })
    (mkIf config.sane.programs.zsh.enabled {
      # enable zsh completions
      environment.pathsToLink = [ "/share/zsh" ];

      programs.zsh = {
        enable = true;
        shellAliases = {
          ":q" = "exit";
          # common typos
          "cd.." = "cd ..";
          "cd../" = "cd ../";
        };
        setOptions = [
          # docs: `man zshoptions`
          # nixos defaults:
          "HIST_FCNTL_LOCK"
          "HIST_IGNORE_DUPS"
          "SHARE_HISTORY"
          # customizations:
          "AUTO_CD"  # type directory name to go there
          "AUTO_MENU"  # show auto-complete menu on double-tab
          "CDABLE_VARS"  # allow auto-cd to use my `hash` aliases -- not just immediate subdirs
          "CLOBBER"  # allow `foo > bar.txt` to overwrite bar.txt
          "NO_CORRECT"  # don't try to correct commands
          "PIPE_FAIL"  # when `cmd_a | cmd_b`, make $? be non-zero if *any* of cmd_a or cmd_b fail
          "RM_STAR_SILENT"  # disable `rm *` confirmations
        ];

        # .zshenv config:
        shellInit = ''
          ZDOTDIR=$HOME/.config/zsh
        '';

        # system-wide .zshrc config:
        interactiveShellInit = ''
          # zmv is a way to do rich moves/renames, with pattern matching/substitution.
          # see for an example: <https://filipe.kiss.ink/zmv-zsh-rename/>
          autoload -Uz zmv

          HISTORY_IGNORE='(sane-shutdown *|sane-reboot *|rm *|nixos-rebuild.* switch|switch)'

          # extra aliases
          # TODO: move to `shellAliases` config?
          function nd() {
            mkdir -p "$1";
            pushd "$1";
          }

          function switch() {
            sudo nixos-rebuild --flake . switch --keep-going;
          }
        '';

        syntaxHighlighting.enable = true;
        vteIntegration = true;
      };

      # enable a command-not-found hook to show nix packages that might provide the binary typed.
      # programs.nix-index.enableZshIntegration = true;
      programs.command-not-found.enable = false;
    })
  ];
}
