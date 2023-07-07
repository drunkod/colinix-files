{ lib
, fetchFromGitea
, htmlq
, tree-sitter
}:

tree-sitter.buildGrammar {
  version = "0.1.0";
  src = fetchFromGitea {
    domain = "git.uninsane.org";
    owner = "colin";
    repo = "tree-sitter-nix-shell";
    rev = "c2fcc8b6ee91af2cb58a38f62c0800f82d783738";
    hash = "sha256-NU7p4KieSkYRhTSgL5qwFJ9n7hGJwTn0rynicfOf9oA=";
  };

  language = "nix-shell";
  location = "tree-sitter-nix-shell";
  generate = true;

  nativeCheckInputs = [ htmlq ];
  checkPhase = ''
    (cd ..; make test)
  '';
  doCheck = true;

  meta = with lib; {
    description = "parse `#!/usr/bin/env nix-shell` scripts with tree-sitter";
    homepage = "https://git.uninsane.org/colin/tree-sitter-nix-shell";
    maintainers = with maintainers; [ colinsane ];
  };
}
