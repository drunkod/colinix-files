{
  thirdparty = {
    curl = {
      url = "https://github.com/curl/curl.git";
      rev = "tags/curl-7_80_0";
      hash = "sha256-ivlhyCAOzaHw5H3tizKYdArSiueH3NPHRG6Jssy2UuE=";
    };
    czmq = {
      url = "https://github.com/zeromq/czmq.git";
      rev = "2a0ddbc4b2dde623220d7f4980ddd60e910cfa78";
      hash = "sha256-FxeJa9u5PB4jsoI+yCfdx2w1jPoUBKkRkMfVi6ljM3c=";
    };
    djvulibre = {
      url = "https://gitlab.com/koreader/djvulibre.git";
      rev = "6a1e5ba1c9ef81c205a4b270c3f121a1e106f4fc";
      hash = "sha256-H0HWR+hpAYLGbBdY3BwxgKPUrWhrIsVMnoURdbn8iIE=";
    };
    # fbink = {  # weird nix/git clone error?
    #   url = "https://github.com/NiLuJe/FBInk.git";
    #   rev = "f562bc15a606524694a6d885bed5d83d03c7eb23";
    # };
    # freetype2 = {  # weird nix/git clone error?
    #   url = "https://gitlab.com/koreader/freetype2.git";
    #   # rev = "VER-2-13-1";
    #   rev = "e4586d960f339cf75e2e0b34aee30a0ed8353c0d";
    # };
    # fribidi = {  # TODO
    #   url = "https://github.com/fribidi/fribidi.git";
    #   rev = "tags/v1.0.12";
    #   rev = "6428d8469e536bcbb6e12c7b79ba6659371c435a";
    #   hash = "sha256-FxeJa9u5PB4jsoI+yCfdx3w1jPoUBKkRkMfVi6ljM3c=";
    # };
    leptonica = {
      url = "https://github.com/DanBloomberg/leptonica.git";
      rev = "1.74.1";
      hash = "sha256-vpgKAPBMQpbF2iCvtX8V+RQ9ynjpWRKN22fOehWxHNE=";
    };
    libjpeg-turbo = {
      url = "https://github.com/libjpeg-turbo/libjpeg-turbo.git";
      rev = "3.0.0";
      hash = "sha256-CEqlV/LzF5okvPwUDyqDBvL4bTGc6TYqfADHtRLPJb4=";
    };
    libk2pdfopt = {
      url = "https://github.com/koreader/libk2pdfopt.git";
      rev = "60b82eeecf71d1776951da970fe8cd2cc5735ded";
      hash = "sha256-JKf6vA5S7VNqk4GzOaX5k1OgAd0vLmoTXusAzR6Otto=";
    };
    libpng = {
      url = "https://github.com/glennrp/libpng.git";
      rev = "v1.6.40";
      hash = "sha256-/994yXMCaX0fVYH94oPPtwc8VDgZNMKXeGUyHd5H3KI=";
    };
    luajit = {
      url = "https://github.com/LuaJIT/LuaJIT";
      rev = "8635cbabf3094c4d8bd00578c7d812bea87bb2d3";
      hash = "sha256-8ij/Zjss8Rz5fKL9LJuRiTQdoT9OVMNOY1a4D2hRcEU=";
    };
    tesseract = {
      url = "https://github.com/tesseract-ocr/tesseract.git";
      rev = "60176fc5ae5e7f6bdef60c926a4b5ea03de2bfa7";
      hash = "sha256-xPhXnMdJJFL0UPAzOWUyx2l4lfjVU154/WgbStq9RDo=";
    };
    zstd = {
      url = "https://github.com/facebook/zstd.git";
      rev = "tags/v1.5.5";
      hash = "sha256-cxoBEwrCA1qrH8o5l0PvKJDcr2M4z1Ek76MISeToENE=";
    };
  };

  externalProjects = {
    # dropbear = TODO
    zlib = {
      url = "http://gentoo.osuosl.org/distfiles/zlib-1.2.13.tar.xz";
      hash = "sha256-0Uw44xOvw1qah2Da3yYEL1HqD10VSwYwox2gVAEH+5g=";
    };
  };
}
