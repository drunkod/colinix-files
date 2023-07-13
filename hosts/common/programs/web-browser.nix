# common settings to toggle (at runtime, in about:config):
#   > security.ssl.require_safe_negotiation

# librewolf is a forked firefox which patches firefox to allow more things
# (like default search engines) to be configurable at runtime.
# many of the settings below won't have effect without those patches.
# see: https://gitlab.com/librewolf-community/settings/-/blob/master/distribution/policies.json

{ config, lib, pkgs, ...}:
with lib;
let
  cfg = config.sane.programs.web-browser.config;
  # allow easy switching between firefox and librewolf with `defaultSettings`, below
  librewolfSettings = {
    browser = pkgs.librewolf-unwrapped;
    extraPrefsFiles = pkgs.librewolf-unwrapped.extraPrefsFiles ++ pkgs.librewolf-pmos-mobile.extraPrefsFiles;
    libName = "librewolf";
    dotDir = ".librewolf";
    cacheDir = ".cache/librewolf";
    desktop = "librewolf.desktop";
  };
  firefoxSettings = {
    browser = pkgs.firefox-esr-unwrapped;
    extraPrefsFiles = pkgs.firefox-pmos-mobile.extraPrefsFiles;
    libName = "firefox";
    dotDir = ".mozilla/firefox";
    cacheDir = ".cache/mozilla";
    desktop = "firefox.desktop";
  };
  # defaultSettings = firefoxSettings;
  defaultSettings = librewolfSettings;

  addon = name: extid: hash: pkgs.fetchFirefoxAddon {
    inherit name hash;
    url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
    # extid can be found by unar'ing the above xpi, and copying browser_specific_settings.gecko.id field
    fixedExtid = extid;
  };
  localAddon = pkg: pkgs.fetchFirefoxAddon {
    inherit (pkg) name;
    src = "${pkg}/share/mozilla/extensions/\\{ec8030f7-c20a-464f-9b0e-13a3a9e97384\\}/${pkg.extid}.xpi";
    fixedExtid = pkg.extid;
  };

  package = pkgs.wrapFirefox cfg.browser.browser {
    # inherit the default librewolf.cfg
    # it can be further customized via ~/.librewolf/librewolf.overrides.cfg
    inherit (cfg.browser) extraPrefsFiles libName;

    extraNativeMessagingHosts = optional cfg.addons.browserpass-extension.enable pkgs.browserpass;
    # extraNativeMessagingHosts = [ pkgs.gopass-native-messaging-host ];

    nixExtensions = concatMap (ext: optional ext.enable ext.package) (attrValues cfg.addons);

    extraPolicies = {
      FirefoxHome = {
        Search = true;
        Pocket = false;
        Snippets = false;
        TopSites = false;
        Highlights = false;
      };
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      PasswordManagerEnabled = false;
      SearchEngines = {
        Default = "DuckDuckGo";
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        SkipOnboarding = true;
        UrlbarInterventions = false;
        WhatsNew = false;
      };

      # these were taken from Librewolf
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
    # extraPrefs = ...
  };

  addonOpts = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
      };
      enable = mkOption {
        type = types.bool;
      };
    };
  };

  configOpts = {
    options = {
      browser = mkOption {
        default = defaultSettings;
        type = types.anything;
      };
      persistData = mkOption {
        description = "optional store name to which persist browsing data (like history)";
        type = types.nullOr types.str;
        default = null;
      };
      persistCache = mkOption {
        description = "optional store name to which persist browser cache";
        type = types.nullOr types.str;
        default = "cryptClearOnBoot";
      };
      addons = mkOption {
        type = types.attrsOf addonOpts;
        default = {};
      };
    };
  };
in
{
  config = mkMerge [
    ({
      sane.programs.web-browser.configOption = mkOption {
        type = types.submodule configOpts;
        default = {};
      };
      sane.programs.web-browser.config.addons = {
        # get names from:
        # - ~/ref/nix-community/nur-combined/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
        # `wget ...xpi`; `unar ...xpi`; `cat */manifest.json | jq '.browser_specific_settings.gecko.id'`
        browserpass-extension = {
          # package = addon "browserpass-ce" "browserpass@maximbaz.com" "sha256-sXgUBbRvMnRpeIW1MTkmTcoqtW/8RDXAkxAq1evFkpc=";
          package = localAddon pkgs.browserpass-extension;
          enable = lib.mkDefault true;
        };

        # TODO: build bypass-paywalls from source? it's mysteriously disappeared from the Mozilla store.
        # bypass-paywalls-clean.package = addon "bypass-paywalls-clean" "{d133e097-46d9-4ecc-9903-fa6a722a6e0e}" "sha256-oUwdqdAwV3DezaTtOMx7A/s4lzIws+t2f08mwk+324k=";
        # bypass-paywalls-clean.enable = lib.mkDefault true;

        # TODO: give these update scripts, make them reachable via `pkgs`
        ether-metamask = {
          package = addon "ether-metamask" "webextension@metamask.io" "sha256-UI83wUUc33OlQYX+olgujeppoo2D2PAUJ+Wma5mH2O0=";
          enable = lib.mkDefault true;
        };
        i2p-in-private-browsing = {
          package = addon "i2p-in-private-browsing" "i2ppb@eyedeekay.github.io" "sha256-dJcJ3jxeAeAkRvhODeIVrCflvX+S4E0wT/PyYzQBQWs=";
          enable = lib.mkDefault config.services.i2p.enable;
        };
        sidebery = {
          package = addon "sidebery" "{3c078156-979c-498b-8990-85f7987dd929}" "sha256-YONfK/rIjlsrTgRHIt3km07Q7KnpIW89Z9r92ZSCc6w=";
          enable = lib.mkDefault true;
        };
        sponsorblock = {
          package = addon "sponsorblock" "sponsorBlocker@ajay.app" "sha256-b/OTFmhSEUZ/CYrYCE4rHVMQmY+Y78k8jSGMoR8vsZA=";
          enable = lib.mkDefault true;
        };
        ublacklist = {
          package = addon "ublacklist" "@ublacklist" "sha256-NZ2FmgJiYnH7j2Lkn0wOembxaEphmUuUk0Ytmb0rNWo=";
          enable = lib.mkDefault true;
        };
        ublock-origin = {
          package = addon "ublock-origin" "uBlock0@raymondhill.net" "sha256-EGGAA+cLUow/F5luNzFG055rFfd3rEyh8hTaL/23pbM=";
          enable = lib.mkDefault true;
        };
      };
    })
    ({
      sane.programs.web-browser = {
        inherit package;

        # env.BROWSER = "${package}/bin/${cfg.browser.libName}";
        env.BROWSER = cfg.browser.libName;  # used by misc tools like xdg-email, as fallback

        # uBlock filter list configuration.
        # specifically, enable the GDPR cookie prompt blocker.
        # data.toOverwrite.filterLists is additive (i.e. it supplements the default filters)
        # this configuration method is documented here:
        # - <https://github.com/gorhill/uBlock/issues/2986#issuecomment-364035002>
        # the specific attribute path is found via scraping ublock code here:
        # - <https://github.com/gorhill/uBlock/blob/master/src/js/storage.js>
        # - <https://github.com/gorhill/uBlock/blob/master/assets/assets.json>
        fs."${cfg.browser.dotDir}/managed-storage/uBlock0@raymondhill.net.json".symlink.text = ''
          {
           "name": "uBlock0@raymondhill.net",
           "description": "ignored",
           "type": "storage",
           "data": {
              "toOverwrite": "{\"filterLists\": [\"fanboy-cookiemonster\"]}"
           }
          }
        '';
        # TODO: this is better suited in `extraPrefs` during `wrapFirefox` call
        fs."${cfg.browser.dotDir}/${cfg.browser.libName}.overrides.cfg".symlink.text = ''
          // if we can't query the revocation status of a SSL cert because the issuer is offline,
          // treat it as unrevoked.
          // see: <https://librewolf.net/docs/faq/#im-getting-sec_error_ocsp_server_error-what-can-i-do>
          defaultPref("security.OCSP.require", false);
        '';
        fs."${cfg.browser.dotDir}/default".dir = {};
        # instruct Firefox to put the profile in a predictable directory (so we can do things like persist just it).
        # XXX: the directory *must* exist, even if empty; Firefox will not create the directory itself.
        fs."${cfg.browser.dotDir}/profiles.ini".symlink.text = ''
          [Profile0]
          Name=default
          IsRelative=1
          Path=default
          Default=1

          [General]
          StartWithLastProfile=1
        '';
      };
    })
    (mkIf config.sane.programs.web-browser.enabled {
      # TODO: move the persistence into the sane.programs API (above)
      # flush the cache to disk to avoid it taking up too much tmp.
      sane.user.persist.byPath."${cfg.browser.cacheDir}".store =
        if (cfg.persistData != null) then
          cfg.persistData
        else
          "cryptClearOnBoot"
        ;

      sane.user.persist.byPath."${cfg.browser.dotDir}/default".store =
        if (cfg.persistData != null) then
          cfg.persistData
        else
          "cryptClearOnBoot"
        ;
    })
  ];
}
