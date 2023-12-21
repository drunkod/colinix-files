{ pkgs, ... }:
{
  sane.programs.audacity = {
    package = pkgs.audacity.override {
      # wxGTK32 uses webkitgtk-4.0.
      # audacity doesn't actually need webkit though, so diable to reduce closure
      wxGTK32 = pkgs.wxGTK32.override {
        withWebKit = false;
      };
    };
  };
}
