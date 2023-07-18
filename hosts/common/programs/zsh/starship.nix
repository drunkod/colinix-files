{ config, lib, pkgs, ...}:

let
  # starship prompt: <https://starship.rs/config/#prompt>
  # populate ~/.config/starship.toml to customize
  starship-init = ''
    eval "$(${pkgs.starship}/bin/starship init zsh)"
  '';
in {
  config = lib.mkIf config.sane.zsh.starship {
    programs.zsh.interactiveShellInit = starship-init;
  };
}
