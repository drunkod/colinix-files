pkgs:

# common settings to toggle (at runtime, in about:config):
#   > security.ssl.require_safe_negotiation

# librewolf is a forked firefox which patches firefox to allow more things
# (like default search engines) to be configurable at runtime.
# many of the settings below won't have effect without those patches.
# see: https://gitlab.com/librewolf-community/settings/-/blob/master/distribution/policies.json
pkgs.wrapFirefox pkgs.librewolf-unwrapped {
  # inherit the default librewolf.cfg
  # it can be further customized via ~/.librewolf/librewolf.overrides.cfg
  inherit (pkgs.librewolf-unwrapped) extraPrefsFiles;
  libName = "librewolf";
  extraPolicies = {
    NoDefaultBookmarks = true;
    SearchEngines = {
      Default = "DuckDuckGo";
    };
    AppUpdateURL = "https://localhost";
    DisableAppUpdate = true;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    DisableSystemAddonUpdate = true;
    DisableFirefoxStudies = true;
    DisableTelemetry = true;
    DisableFeedbackCommands = true;
    DisablePocket = true;
    DisableSetDesktopBackground = false;
    Extensions = {
      Install = [
        "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
        "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi"
        "https://addons.mozilla.org/firefox/downloads/latest/bypass-paywalls-clean/latest.xpi"
        "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi"
        "https://addons.mozilla.org/firefox/downloads/latest/ether-metamask/latest.xpi"
      ];
      # remove many default search providers
      Uninstall = [
        "google@search.mozilla.org"
        "bing@search.mozilla.org"
        "amazondotcom@search.mozilla.org"
        "ebay@search.mozilla.org"
        "twitter@search.mozilla.org"
      ];
    };
    # XXX doesn't seem to have any effect...
    # docs: https://github.com/mozilla/policy-templates#homepage
    # Homepage = {
    #   HomepageURL = "https://uninsane.org/";
    #   StartPage = "homepage";
    # };
    # NewTabPage = true;
  };
}
