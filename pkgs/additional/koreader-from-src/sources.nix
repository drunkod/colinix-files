{
  thirdparty = [
    {
      url = "https://github.com/LuaJIT/LuaJIT";
      rev = "8635cbabf3094c4d8bd00578c7d812bea87bb2d3";
      hash = "sha256-8ij/Zjss8Rz5fKL9LJuRiTQdoT9OVMNOY1a4D2hRcEU=";
      name = "luajit";
    }
    {
      url = "https://github.com/libjpeg-turbo/libjpeg-turbo.git";
      rev = "3.0.0";
      hash = "sha256-CEqlV/LzF5okvPwUDyqDBvL4bTGc6TYqfADHtRLPJb4=";
      name = "libjpeg-turbo";
    }
    {
      url = "https://gitlab.com/koreader/djvulibre.git";
      rev = "6a1e5ba1c9ef81c205a4b270c3f121a1e106f4fc";
      hash = "sha256-H0HWR+hpAYLGbBdY3BwxgKPUrWhrIsVMnoURdbn8iIE=";
      name = "djvulibre";
    }
    {
      url = "https://github.com/glennrp/libpng.git";
      rev = "v1.6.40";
      hash = "sha256-/994yXMCaX0fVYH94oPPtwc8VDgZNMKXeGUyHd5H3KI=";
      name = "libpng";
    }
    {
      url = "https://github.com/tesseract-ocr/tesseract.git";
      rev = "60176fc5ae5e7f6bdef60c926a4b5ea03de2bfa7";
      hash = "sha256-xPhXnMdJJFL0UPAzOWUyx2l4lfjVU154/WgbStq9RDo=";
      name = "tesseract";
    }
    {
      url = "https://github.com/DanBloomberg/leptonica.git";
      rev = "1.74.1";
      hash = "sha256-vpgKAPBMQpbF2iCvtX8V+RQ9ynjpWRKN22fOehWxHNE=";
      name = "leptonica";
    }
  ];

  externalProjects = {
    zlib = {
      url = "http://gentoo.osuosl.org/distfiles/zlib-1.2.13.tar.xz";
      hash = "sha256-0Uw44xOvw1qah2Da3yYEL1HqD10VSwYwox2gVAEH+5g=";
    };
  };
}
