# starship prompt: <https://starship.rs/config/#prompt>
{ config, lib, pkgs, ...}:

let
  enabled = config.sane.zsh.starship;
  toml = pkgs.formats.toml {};
in {
  config = lib.mkIf config.sane.zsh.starship {
    sane.programs.zsh = lib.mkIf enabled {
      fs.".config/zsh/.zshrc".symlink.text = ''
        eval "$(${pkgs.starship}/bin/starship init zsh)"
      '';
      fs.".config/starship.toml".symlink.target = toml.generate "starship.toml" {
        format = "$all";
      };
    };
  };
}
