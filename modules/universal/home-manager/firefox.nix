# common settings to toggle (at runtime, in about:config):
#   > security.ssl.require_safe_negotiation

# librewolf is a forked firefox which patches firefox to allow more things
# (like default search engines) to be configurable at runtime.
# many of the settings below won't have effect without those patches.
# see: https://gitlab.com/librewolf-community/settings/-/blob/master/distribution/policies.json

{ config, lib, pkgs, ...}:
with lib;
let
  cfg = config.sane.web-browser;
  # allow easy switching between firefox and librewolf with `defaultSettings`, below
  librewolfSettings = {
    browser = pkgs.librewolf-unwrapped;
    # browser = pkgs.librewolf-unwrapped.overrideAttrs (drv: {
    #   # this allows side-loading unsigned addons
    #   MOZ_REQUIRE_SIGNING = false;
    # });
    libName = "librewolf";
    dotDir = ".librewolf";
    desktop = "librewolf.desktop";
  };
  firefoxSettings = {
    browser = pkgs.firefox-esr-unwrapped;
    libName = "firefox";
    dotDir = ".mozilla/firefox";
    desktop = "firefox.desktop";
  };
  defaultSettings = firefoxSettings;
  # defaultSettings = librewolfSettings;

  package = pkgs.wrapFirefox cfg.browser {
    # inherit the default librewolf.cfg
    # it can be further customized via ~/.librewolf/librewolf.overrides.cfg
    inherit (pkgs.librewolf-unwrapped) extraPrefsFiles;
    inherit (cfg) libName;

    extraNativeMessagingHosts = [ pkgs.browserpass ];
    # extraNativeMessagingHosts = [ pkgs.gopass-native-messaging-host ];

    nixExtensions = let
      addon = name: extid: hash: pkgs.fetchFirefoxAddon {
        inherit name hash;
        url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
        fixedExtid = extid;
      };
      localAddon = pkg: pkgs.fetchFirefoxAddon {
        inherit (pkg) name;
        src = "${pkg}/share/mozilla/extensions/\\{ec8030f7-c20a-464f-9b0e-13a3a9e97384\\}/${pkg.extid}.xpi";
        fixedExtid = pkg.extid;
      };
    in [
      (addon "ublock-origin" "uBlock0@raymondhill.net" "sha256-C+VQyaJ8BA0ErXGVTdnppJZ6J9SP+izf6RFxdS4VJoU=")
      (addon "sponsorblock" "sponsorBlocker@ajay.app" "sha256-au5GGn22n4i6VrdOKqNMOrWdMoVCcpLdjO2wwRvyx7E=")
      (addon "bypass-paywalls-clean" "{d133e097-46d9-4ecc-9903-fa6a722a6e0e}" "sha256-m14onUlnpLDPHezA/soKygcc76tF1fLG52tM/LkbAXQ=")
      (addon "sidebery" "{3c078156-979c-498b-8990-85f7987dd929}" "sha256-YONfK/rIjlsrTgRHIt3km07Q7KnpIW89Z9r92ZSCc6w=")
      (addon "ether-metamask" "webextension@metamask.io" "sha256-dnpwKpNF0KgHMAlz5btkkZySjMsnrXECS35ClkD2XHc=")
      # (addon "browserpass-ce" "browserpass@maximbaz.com" "sha256-sXgUBbRvMnRpeIW1MTkmTcoqtW/8RDXAkxAq1evFkpc=")
      (localAddon pkgs.browserpass-extension)
    ];

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

      # remove many default search providers
      # XXX this seems to prevent the `nixExtensions` from taking effect
      # Extensions.Uninstall = [
      #   "google@search.mozilla.org"
      #   "bing@search.mozilla.org"
      #   "amazondotcom@search.mozilla.org"
      #   "ebay@search.mozilla.org"
      #   "twitter@search.mozilla.org"
      # ];
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
  options = {
    sane.web-browser = mkOption {
      default = defaultSettings;
      type = types.attrs;
    };
  };
  config = {
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
      home.file."${cfg.dotDir}/managed-storage/uBlock0@raymondhill.net.json".text = ''
        {
         "name": "uBlock0@raymondhill.net",
         "description": "ignored",
         "type": "storage",
         "data": {
            "toOverwrite": "{\"filterLists\": [\"fanboy-cookiemonster\"]}"
         }
        }
      '';
      home.file."${cfg.dotDir}/${cfg.libName}.overrides.cfg".text = ''
        // if we can't query the revocation status of a SSL cert because the issuer is offline,
        // treat it as unrevoked.
        // see: <https://librewolf.net/docs/faq/#im-getting-sec_error_ocsp_server_error-what-can-i-do>
        defaultPref("security.OCSP.require", false);
      '';
    };
  };
}
