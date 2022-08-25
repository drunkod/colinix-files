{ pkgs, fetchFromGitHub, ... }:

# buildVimPluginFrom2Nix {
pkgs.vimUtils.buildVimPlugin {
  pname = "nabla";
  version = "2022-08-17";
  src = fetchFromGitHub {
    owner = "jbyuki";
    repo = "nabla.nvim";
    rev = "5379635d71b9877eaa4df822e8a2a5c575d808b0";
    sha256 = "sha256-1VabgTnOSsfdhmHnfXl/h9djgNV3Gqro5VOr8ZbUlWw=";
  };
  meta.homepage = "https://github.com/jbyuki/nabla.nvim/";
}
