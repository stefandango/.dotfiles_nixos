{ lib, pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    # Enterprise policies — stronger than prefs (locked, can't be re-enabled by accident).
    # https://mozilla.github.io/policy-templates/
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = false;          # keep — sync is useful
      DisableFormHistory = false;              # keep — usability
      DisableFirefoxScreenshots = false;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = true;                # keep — usability
      PasswordManagerEnabled = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };
      FirefoxHome = {
        Search = true;
        TopSites = true;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = true;
        MoreFromMozilla = false;
      };
      # HTTPS-only — modern web is fine with this; you can click through if needed
      HttpsOnlyMode = "enabled";
      # DNS over HTTPS — mode 2 = TRR first, system fallback (no breakage on captive portals)
      DNSOverHTTPS = {
        Enabled = true;
        Locked = false;
      };

      # Force-installed extensions. Auto-updated from AMO; settings are NOT managed.
      # To add: find the extension ID via about:debugging → This Firefox → Internal UUID,
      # or in the extension's manifest.json. Then grab the AMO slug from its addons.mozilla.org URL.
      ExtensionSettings = {
        # Block any extension not explicitly listed below? Uncomment to lock down hard.
        # "*".installation_mode = "blocked";

        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
        };

        # ── Add more here, e.g.: ─────────────────────────────────────────────
        # Bitwarden
        # "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
        #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        #   installation_mode = "force_installed";
        #   private_browsing = true;
        # };
        #
        # Multi-Account Containers
        # "@testpilot-containers" = {
        #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
        #   installation_mode = "force_installed";
        # };
      };
    };

    profiles.default = {
      id = 0;
      isDefault = true;

      settings = {
        # ── Telemetry ────────────────────────────────────────────────────────
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.opt-out" = true;
        "toolkit.coverage.endpoint.base" = "";
        "browser.ping-centre.telemetry" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;

        # ── Studies / Normandy / experiments ─────────────────────────────────
        "app.shield.optoutstudies.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";

        # ── Crash reports ────────────────────────────────────────────────────
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;

        # ── Pocket / sponsored / Mozilla ads on new tab ──────────────────────
        "extensions.pocket.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;

        # ── Tracking protection (Strict ETP — partitions cookies/storage) ────
        "browser.contentblocking.category" = "strict";
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.partition.network_state.ocsp_cache" = true;
        "privacy.partition.serviceWorkers" = true;

        # Lighter fingerprinting protection (introduced FF 119+).
        # Unlike resistFingerprinting, this won't force English/letterboxing/fixed timezone.
        "privacy.fingerprintingProtection" = true;

        # ── Referer policy: trim to origin on cross-origin (privacy + compat) ─
        "network.http.referer.XOriginTrimmingPolicy" = 2;

        # ── HTTPS only ───────────────────────────────────────────────────────
        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_ever_enabled" = true;

        # ── DNS over HTTPS (mode 2 = TRR first, fallback) ────────────────────
        "network.trr.mode" = 2;

        # ── Disable speculative/prefetch leaks (minor perf cost) ─────────────
        "network.prefetch-next" = false;
        "network.predictor.enabled" = false;
        "network.predictor.enable-prefetch" = false;
        "browser.urlbar.speculativeConnect.enabled" = false;

        # ── Search: keep suggestions (usability), strip URL trackers ─────────
        "browser.search.suggest.enabled" = true;
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.trimURLs" = false;
        "browser.urlbar.update2.engineAliasRefresh" = true;
        "privacy.query_stripping.enabled" = true;
        "privacy.query_stripping.enabled.pbmode" = true;

        # ── Misc telemetry endpoints / features ──────────────────────────────
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "browser.discovery.enabled" = false;
        "default-browser-agent.enabled" = false;

        # ── New tab page: clean ──────────────────────────────────────────────
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
        "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;

        # ── Keep these ENABLED for security/usability (intentional) ──────────
        # SafeBrowsing — yes, sends URL hashes to Google but it's a real protection
        "browser.safebrowsing.malware.enabled" = true;
        "browser.safebrowsing.phishing.enabled" = true;
        "browser.safebrowsing.downloads.enabled" = true;

        # NOT setting these (would hurt usability/perf, per your ask):
        #   privacy.resistFingerprinting       — letterboxes, forces en-US, fixed TZ
        #   privacy.firstparty.isolate         — breaks logins on federated sites
        #   webgl.disabled                      — breaks maps, games, many sites
        #   javascript.options.*                — breaks the modern web
        #   media.peerconnection.enabled=false  — breaks WebRTC (calls, screenshare)
      };
    };
  };
}
