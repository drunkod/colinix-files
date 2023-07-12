{ komikku
, fetchFromGitLab
}:
komikku.overrideAttrs (upstream: {
  src = fetchFromGitLab {
    owner = "valos";
    repo = "Komikku";
    rev = "7dcf2b3d0ba685396872780b1ce75d01cbe02ebe";
    hash = "sha256-LzgHPuIpxy0ropiNycdxZP6onjK2JpMRqkkdmJGA4nE=";
  };
})
