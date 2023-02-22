{ sane-lib, ... }:
{
  # .ignore file is read by ripgrep (rg), silver searcher (ag), maybe others.
  # ignore translation files by default when searching, as they tend to have
  # a LOT of duplicate text.
  sane.user.fs.".ignore" = sane-lib.fs.wantedText ''
    po/
  '';
}
