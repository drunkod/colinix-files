# common settings to toggle (at runtime, in about:config):
#   > security.ssl.require_safe_negotiation

# librewolf is a forked firefox which patches firefox to allow more things
# (like default search engines) to be configurable at runtime.
# many of the settings below won't have effect without those patches.
# see: https://gitlab.com/librewolf-community/settings/-/blob/master/distribution/policies.json

{ config, lib, pkgs, sane-lib, ...}:
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
    cacheDir = ".cache/librewolf";  # TODO: is it?
    desktop = "librewolf.desktop";
  };
  firefoxSettings = {
    browser = pkgs.firefox-esr-unwrapped;
    libName = "firefox";
    dotDir = ".mozilla/firefox";
    cacheDir = ".cache/mozilla";
    desktop = "firefox.desktop";
  };
  defaultSettings = firefoxSettings;
  # defaultSettings = librewolfSettings;

  package = pkgs.wrapFirefox cfg.browser.browser {
    # inherit the default librewolf.cfg
    # it can be further customized via ~/.librewolf/librewolf.overrides.cfg
    inherit (pkgs.librewolf-unwrapped) extraPrefsFiles;
    inherit (cfg.browser) libName;

    extraNativeMessagingHosts = [ pkgs.browserpass ];
    # extraNativeMessagingHosts = [ pkgs.gopass-native-messaging-host ];

    nixExtensions = let
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
    in [
      # get names from:
      # - ~/ref/nix-community/nur-combined/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
      # `wget ...xpi`; `unar ...xpi`; `cat */manifest.json | jq '.browser_specific_settings.gecko.id'`
      (addon "ublock-origin" "uBlock0@raymondhill.net" "sha256-a/ivUmY1P6teq9x0dt4CbgHt+3kBsEMMXlOfZ5Hx7cg=")
      (addon "sponsorblock" "sponsorBlocker@ajay.app" "sha256-d2K3ufvurWnYVzqLbyR//MgejybkY9exitAf9RdLNRo=")
      (addon "bypass-paywalls-clean" "{d133e097-46d9-4ecc-9903-fa6a722a6e0e}" "sha256-JOj5P7c2JTTReHCRZXm4BscaGr3i+9Y4Ey/y621x8PI=")
      (addon "sidebery" "{3c078156-979c-498b-8990-85f7987dd929}" "sha256-YONfK/rIjlsrTgRHIt3km07Q7KnpIW89Z9r92ZSCc6w=")
      (addon "ether-metamask" "webextension@metamask.io" "sha256-G+MwJDOcsaxYSUXjahHJmkWnjLeQ0Wven8DU/lGeMzA=")
      (addon "ublacklist" "@ublacklist" "sha256-RqY5iHzbL2qizth7aguyOKWPyINXmrwOlf/OsfqAS48=")
      (addon "i2p-in-private-browsing" "i2ppb@eyedeekay.github.io" "sha256-dJcJ3jxeAeAkRvhODeIVrCflvX+S4E0wT/PyYzQBQWs=")
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
    sane.web-browser.browser = mkOption {
      default = defaultSettings;
      type = types.attrs;
    };
    sane.web-browser.persistData = mkOption {
      description = "optional store name to which persist browsing data (like history)";
      type = types.nullOr types.str;
      default = null;
    };
    sane.web-browser.persistCache = mkOption {
      description = "optional store name to which persist browser cache";
      type = types.nullOr types.str;
      default = "cryptClearOnBoot";
    };
  };

  config = lib.mkIf config.sane.home-manager.enable {

    # uBlock filter list configuration.
    # specifically, enable the GDPR cookie prompt blocker.
    # data.toOverwrite.filterLists is additive (i.e. it supplements the default filters)
    # this configuration method is documented here:
    # - <https://github.com/gorhill/uBlock/issues/2986#issuecomment-364035002>
    # the specific attribute path is found via scraping ublock code here:
    # - <https://github.com/gorhill/uBlock/blob/master/src/js/storage.js>
    # - <https://github.com/gorhill/uBlock/blob/master/assets/assets.json>
    sane.fs."/home/colin/${cfg.browser.dotDir}/managed-storage/uBlock0@raymondhill.net.json" = sane-lib.fs.wantedText ''
      {
       "name": "uBlock0@raymondhill.net",
       "description": "ignored",
       "type": "storage",
       "data": {
          "toOverwrite": "{\"filterLists\": [\"fanboy-cookiemonster\"]}"
       }
      }
    '';
    sane.fs."/home/colin/${cfg.browser.dotDir}/${cfg.browser.libName}.overrides.cfg" = sane-lib.fs.wantedText ''
      // if we can't query the revocation status of a SSL cert because the issuer is offline,
      // treat it as unrevoked.
      // see: <https://librewolf.net/docs/faq/#im-getting-sec_error_ocsp_server_error-what-can-i-do>
      defaultPref("security.OCSP.require", false);
    '';

    sane.packages.extraGuiPkgs = [ package ];
    # flood the cache to disk to avoid it taking up too much tmp
    sane.persist.home.byPath."${cfg.browser.cacheDir}" = lib.mkIf (cfg.persistCache != null) {
      store = cfg.persistCache;
    };

    sane.persist.home.byPath."${cfg.browser.dotDir}" = lib.mkIf (cfg.persistData != null) {
      store = cfg.persistData;
    };
  };
}
