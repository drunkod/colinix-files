{ callPackage }:
{
  feedsearch-crawler = callPackage ./feedsearch-crawler { };
  sane-lib = (callPackage ../additional/sane-scripts { }).lib;
}
