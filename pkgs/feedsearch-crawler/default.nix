{ lib
, fetchFromGitHub
, python3
}:

python3.pkgs.buildPythonApplication rec {
  pname = "feedsearch-crawler";
  version = "2022-05-28";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "DBeath";
    repo = "feedsearch-crawler";
    rev = "f49a6f5a07e796e359c4482fd29305b1a019f71f";
    hash = "sha256-pzvyeXzqdi8pRjk2+QjKhJfgtxbgVT6C08K9fhVFVmY=";
  };

  nativeBuildInputs = with python3.pkgs; [
    poetry-core
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace 'w3lib = "^1.22.0"' 'w3lib = "*"' \
      --replace 'aiodns = "^2.0.0"' 'aiodns = "*"' \
      --replace 'uvloop = "^0.15.2"' 'uvloop = "*"'
  '';

  propagatedBuildInputs = with python3.pkgs; [
    aiodns
    aiohttp
    beautifulsoup4
    brotlipy
    cchardet
    feedparser
    python-dateutil
    uvloop
    w3lib
    yarl
  ];

  meta = with lib; {
    homepage = "https://feedsearch.dev";
    description = "Crawl sites for RSS, Atom, and JSON feeds";
    license = licenses.mit;
    maintainers = with maintainers; [ colinsane ];
  };
}
