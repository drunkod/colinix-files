{ pkgs }:

(pkgs.alsa-ucm-conf.overrideAttrs (upstream: {
  patches = (upstream.patches or []) ++ [
    (pkgs.fetchpatch {
      # "Add UCM for PinePhone"
      # we need this for audio to work on the Pinephone
      url = "https://github.com/alsa-project/alsa-ucm-conf/pull/134.diff";
      sha256 = "sha256-hFpp8jQo8fQRqKrSnBEi5eh1Zf/x+1o+p40ML5iuWJM=";
    })
  ];
}))

