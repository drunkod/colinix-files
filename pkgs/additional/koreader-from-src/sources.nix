{
  thirdparty = {
    curl = {
      url = "https://github.com/curl/curl.git";
      rev = "tags/curl-7_80_0";
      hash = "sha256-kzozc0Io+1f4UMivSV2IhzJDQXmad4wNhXN/Y2Lsg3Q=";
    };
    czmq = {
      url = "https://github.com/zeromq/czmq.git";
      rev = "2a0ddbc4b2dde623220d7f4980ddd60e910cfa78";
      hash = "sha256-p4Cl2PLVgRQ0S4qr3VClJXjvAd2LUBU9oRUvOCfVnyw=";
    };
    djvulibre = {
      url = "https://gitlab.com/koreader/djvulibre.git";
      rev = "6a1e5ba1c9ef81c205a4b270c3f121a1e106f4fc";
      hash = "sha256-OWSbxdr93FH3ed0D+NSFWIah7VDTcL3LIGOciY+f4dk=";
    };
    fbink = {
      url = "https://github.com/NiLuJe/FBInk.git";
      rev = "f562bc15a606524694a6d885bed5d83d03c7eb23";
      hash = "sha256-JlanCl4XQBFnrpRIEsowSeUI7wSa9RoQc5h3pkMHXA8=";
    };
    freetype2 = {
      url = "https://gitlab.com/koreader/freetype2.git";
      rev = "VER-2-13-1";
      hash = "sha256-rQN+hRzrs+KGgp8+n1VJzOOwtKUcRuSE/s/r8/xOUdI=";
    };
    fribidi = {
      url = "https://github.com/fribidi/fribidi.git";
      rev = "tags/v1.0.12";
      hash = "sha256-L4m/F9rs8fiv9rSf8oy7P6cthhupc6R/lCv30PLiQ4M=";
    };
    leptonica = {
      url = "https://github.com/DanBloomberg/leptonica.git";
      rev = "1.74.1";
      hash = "sha256-SDXKam768xvZZvTbXe3sssvZyeLEEiY97Vrzx8hoc6g=";
    };
    libjpeg-turbo = {
      url = "https://github.com/libjpeg-turbo/libjpeg-turbo.git";
      rev = "3.0.0";
      hash = "sha256-mIeSBP65+rWOCRS/33MPqGUpemBee2qR45CZ6H00Hak=";
    };
    libk2pdfopt = {
      url = "https://github.com/koreader/libk2pdfopt.git";
      rev = "60b82eeecf71d1776951da970fe8cd2cc5735ded";
      hash = "sha256-9UcDr9e4GZCZ78moRs1ADAt4Xl7z3vR93KDexXEHvhw=";
    };
    libpng = {
      url = "https://github.com/glennrp/libpng.git";
      rev = "v1.6.40";
      hash = "sha256-Rad7Y5Z9PUCipBTQcB7LEP8fIVTG3JsnMeknUkZ/rRg=";
    };
    luajit = {
      url = "https://github.com/LuaJIT/LuaJIT";
      rev = "8635cbabf3094c4d8bd00578c7d812bea87bb2d3";
      hash = "sha256-pfMNQFulW6AEwAVPxn9wUdbRg3ViHbGVCCke5NSIgTo=";
    };
    tesseract = {
      url = "https://github.com/tesseract-ocr/tesseract.git";
      rev = "60176fc5ae5e7f6bdef60c926a4b5ea03de2bfa7";
      hash = "sha256-FQvlrJ+Uy7+wtUxBuS5NdoToUwNRhYw2ju8Ya8MLyQw=";
    };
    zstd = {
      url = "https://github.com/facebook/zstd.git";
      rev = "tags/v1.5.5";
      hash = "sha256-tHHHIsQU7vJySrVhJuMKUSq11MzkmC+Pcsj00uFJdnQ=";
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
