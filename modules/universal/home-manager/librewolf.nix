# common settings to toggle (at runtime, in about:config):
#   > security.ssl.require_safe_negotiation

# librewolf is a forked firefox which patches firefox to allow more things
# (like default search engines) to be configurable at runtime.
# many of the settings below won't have effect without those patches.
# see: https://gitlab.com/librewolf-community/settings/-/blob/master/distribution/policies.json

{ config, lib, pkgs, ...}:
let
  package = pkgs.wrapFirefox pkgs.librewolf-unwrapped {
    # inherit the default librewolf.cfg
    # it can be further customized via ~/.librewolf/librewolf.overrides.cfg
    inherit (pkgs.librewolf-unwrapped) extraPrefsFiles;
    libName = "librewolf";

    extraNativeMessagingHosts = [ pkgs.browserpass ];
    # extraNativeMessagingHosts = [ pkgs.gopass-native-messaging-host ];

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
        Install = let
          addon = pkg: addonId: "${pkg}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi";
        in with pkgs.firefox-addons; [
          # the extension key is found by building and checking the output: `nix build '.#rycee.firefox-addons.<foo>'`
          # or by taking the `addonId` input to `buildFirefoxXpiAddon` in rycee's firefox-addons repo
          (addon ublock-origin "uBlock0@raymondhill.net")
          (addon sponsorblock "sponsorBlocker@ajay.app")
          (addon bypass-paywalls-clean "{d133e097-46d9-4ecc-9903-fa6a722a6e0e}")
          (addon sidebery "{3c078156-979c-498b-8990-85f7987dd929}")
          (addon browserpass "browserpass@maximbaz.com")
          (addon metamask "webextension@metamask.io")
          # extensions can alternatively be installed by URL, in which case they are fetched (and cached) on first run.
          # "https://addons.mozilla.org/firefox/downloads/latest/gopass-bridge/latest.xpi"
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
  };
in
{
  # XXX: although home-manager calls this option `firefox`, we can use other browsers and it still mostly works.
  home-manager.users.colin = lib.mkIf (config.sane.gui.enable) {
    programs.firefox = {
      enable = true;
      inherit package;
    };

    # uBlock filter list configuration.
    # specifically, enable the GDPR cookie prompt blocker.
    # data.toOverwrite.filterLists is additive (i.e. it supplements the default filters)
    # this configuration method is documented here:
    # - <https://github.com/gorhill/uBlock/issues/2986#issuecomment-364035002>
    # the specific attribute path is found via scraping ublock code here:
    # - <https://github.com/gorhill/uBlock/blob/master/src/js/storage.js>
    # - <https://github.com/gorhill/uBlock/blob/master/assets/assets.json>
    home.file.".librewolf/managed-storage/uBlock0@raymondhill.net.json".text = ''
      {
       "name": "uBlock0@raymondhill.net",
       "description": "ignored",
       "type": "storage",
       "data": {
          "toOverwrite": "{\"filterLists\": [\"fanboy-cookiemonster\"]}"
       }
      }
    '';
    home.file.".librewolf/librewolf.overrides.cfg".text = ''
      // if we can't query the revocation status of a SSL cert because the issuer is offline,
      // treat it as unrevoked.
      // see: <https://librewolf.net/docs/faq/#im-getting-sec_error_ocsp_server_error-what-can-i-do>
      defaultPref("security.OCSP.require", false);
    '';
  };
}
