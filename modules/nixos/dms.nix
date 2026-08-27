{ config, lib, pkgs, inputs, vars, ... }:

# TEMP[dms-trial]: DankMaterialShell, evaluated as a replacement for the
# waybar + rofi + swaync + hyprlock/hypridle stack. Selected by `desktopShell`
# in ./default.nix — this module is only imported when that is "dms", so the
# two shells can never both claim org.kde.StatusNotifierWatcher or
# org.freedesktop.Notifications.
# TEMP-CHECK: recheck_after 2026-10-01

let
  themeNames = [ "graphite" "slate" "umber" "moss" "mono" ];

  # Our palette is a neutral ramp (black < bg < inactive < gray < comment <
  # text < fg) plus an accent and three semantic colours. Material 3 wants
  # tonal *roles* instead, so map the ramp onto the surface hierarchy and let
  # the accent drive primary. Colours arrive as bare hex (no "#").
  toM3 = p: {
    name = p.name;

    # Accent drives every "primary" role. primaryText sits ON primary, so it
    # has to be the dark end of the ramp, not the light one.
    primary = "#${p.accent}";
    primaryText = "#${p.bg}";
    primaryContainer = "#${p.accentDim}";
    surfaceTint = "#${p.accent}";

    # `purple` is deliberately a neutral slate in our palette (see the comment
    # in theme/colors.nix), which is exactly what a secondary role wants.
    secondary = "#${p.purple}";

    # Surface hierarchy walks up the neutral ramp.
    background = "#${p.black}";
    backgroundText = "#${p.fg}";
    surface = "#${p.bg}";
    surfaceText = "#${p.fg}";
    surfaceVariant = "#${p.inactive}";
    surfaceVariantText = "#${p.text}";
    surfaceContainer = "#${p.inactive}";
    surfaceContainerHigh = "#${p.gray}";
    surfaceContainerHighest = "#${p.comment}";
    outline = "#${p.gray}";

    error = "#${p.danger}";
    warning = "#${p.warning}";
    info = "#${p.cyan}";
  };

  # DMS reads { dark, light }; with only `dark` present it reuses it for light
  # mode (Theme.qml:1650-1652). Our themes are dark-only, so that is correct.
  mkTheme = name:
    let palette = builtins.fromJSON (builtins.readFile ../../theme/themes/${name}.json);
    in pkgs.writeText "dms-${name}.json" (builtins.toJSON { dark = toM3 palette; });

  dmsThemes = pkgs.linkFarm "dms-themes"
    (map (n: { name = "${n}.json"; path = mkTheme n; }) themeNames);

  # ── Seed configuration ────────────────────────────────────────────────────
  # Captured from a live session with `dms ipc call settings dump` after
  # hand-tuning, then folded back in here. This is only the STARTING state:
  # the activation script writes it once and DMS owns the file afterwards, so
  # re-dump and update this block when the look settles again.
  dmsSeedSettings = {
    configVersion = 16;

    # Wallpaper-derived colours, chosen over the pinned Graphite palette. The
    # five generated themes stay available to switch back to via the Settings
    # UI (currentThemeName = "custom").
    currentThemeName = "dynamic";
    currentThemeCategory = "dynamic";
    customThemeFile = "${dmsThemes}/graphite.json";

    cornerRadius = 12;
    popupTransparency = 0.96;
    m3ElevationEnabled = false;
    barElevationEnabled = false;
    systemTrayIconTintMode = "monochrome";

    fontFamily = "Inter";
    monoFontFamily = "MonoLisa Nerd Font";
    fontWeight = 600;               # matches waybar's font-weight: 600

    clockFormat = "24h";
    clockDateFormat = "d/M";
    lockDateFormat = "dddd, MMMM d";
    firstDayOfWeek = 1;             # Monday

    # Without these DMS renders the active workspace as an empty coloured
    # lozenge — no index, no icons.
    showWorkspaceIndex = true;
    showWorkspaceApps = true;
    maxWorkspaceIcons = 4;

    # Idle and lock. DMS owns both now that hypridle is not started, and every
    # one of its timeouts defaults to 0 = disabled — so without these the
    # machine never locks and never blanks. Values reproduce the old hypridle
    # listeners exactly (lock at 600s, monitors off at 660s). Suspend stays 0:
    # this host disables Suspend/Hibernate outright in systemd.sleep.settings.
    acLockTimeout = 600;
    acMonitorTimeout = 660;
    acSuspendTimeout = 0;
    batteryLockTimeout = 600;
    batteryMonitorTimeout = 660;
    batterySuspendTimeout = 0;
    lockBeforeSuspend = true;       # was hypridle's before_sleep_cmd

    # Dank Island rather than the classic bar. The island renders whichever
    # barConfig its id points at, so the layout below drives both.
    dankIslandBarId = "default";
    dankIslandHomeStatusSlot = "left";
    dankIslandHomeWeatherSlot = "right";

    # Launcher search prefixes.
    builtInPluginSettings = {
      dms_settings_search.trigger = "?";
      dms_clipboard_search.trigger = "cb";
      dms_qr_generator.trigger = "qrg";
    };

    # This list REPLACES the defaults, so the stock entries are repeated.
    # builtin_tailscale is absent from DMS's defaults and its loader
    # deactivates itself when no entry is present — so Tailscale appears
    # nowhere at all until it is named here.
    controlCenterWidgets = [
      { id = "volumeSlider";      enabled = true; width = 50; }
      { id = "brightnessSlider";  enabled = true; width = 50; }
      { id = "wifi";              enabled = true; width = 50; }
      { id = "bluetooth";         enabled = true; width = 50; }
      { id = "builtin_tailscale"; enabled = true; width = 100; }
      { id = "audioOutput";       enabled = true; width = 50; }
      { id = "audioInput";        enabled = true; width = 50; }
      { id = "doNotDisturb";      enabled = true; width = 50; }
      { id = "idleInhibitor";     enabled = true; width = 50; }
      { id = "nightMode";         enabled = true; width = 50; }
      { id = "darkMode";          enabled = true; width = 50; }
    ];

    # DMS ships matugen templates that write theme files for other apps.
    # Hyprland colours come from theme-switcher.sh via hyprctl and kitty from
    # theme-override.conf; letting DMS also write them would mean two writers
    # for one file. GTK/Qt are pinned static in theme/theming.nix.
    matugenTemplateHyprland = false;
    matugenTemplateKitty = false;
    matugenTemplateGtk = false;
    matugenTemplateQt5ct = false;
    matugenTemplateQt6ct = false;
    matugenTemplateQtengine = false;
    matugenTemplateNeovim = false;
    matugenTemplateFirefox = false;
    matugenTemplateZenBrowser = false;
    matugenTemplateVscode = false;
    matugenTemplateNiri = false;
    matugenTemplateMangowc = false;

    barConfigs = [{
      id = "default";
      name = "Main Bar";
      enabled = true;
      position = 0;                     # top
      screenPreferences = [ "all" ];

      leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
      centerWidgets = [ "music" "clock" "weather" ];

      # `systemUpdate` is deliberately absent: DMS's updater only knows
      # pacman/paru/yay, so on NixOS the widget can never report anything.
      # `vpn` is absent too — it is NetworkManager-only, and Tailscale is
      # surfaced through the Control Center widget instead.
      rightWidgets = [
        "clipboard"
        "diskUsage" "memUsage" "cpuUsage" "cpuTemp" "gpuTemp"
        "systemTray" "notificationButton"
        "controlCenterButton" "powerMenuButton"
      ];

      # These two names are misleading: they are opacity, not transparency.
      # transparency = 0 makes the bar surface invisible, which leaves every
      # widget drawing its own background — that is what reads as "a border
      # around each module". Put the surface back on the bar and flatten the
      # widgets so the row reads as one object.
      transparency = 0.85;
      widgetTransparency = 0.0;
      noBackground = false;
      widgetOutlineEnabled = false;
      borderEnabled = false;
      gothCornersEnabled = false;
      shadowIntensity = 0;

      # Float it off the screen edges so the rounded corners read as corners
      # rather than being clipped by the edge of the display.
      attachToScreenEdge = false;
      barLengthPadding = 14;
      bottomGap = 6;

      spacing = 4;
      innerPadding = 6;
      widgetPadding = 12;
      squareCorners = false;
      popupGapsAuto = true;
      maximizeWidgetIcons = false;
    }];
  };

  dmsSeedFile = pkgs.writeText "dms-settings-seed.json"
    (builtins.toJSON dmsSeedSettings);

  dmsSettingsPath = ".config/DankMaterialShell/settings.json";
in
{
  # Taken as a module function so `lib` here is home-manager's extended lib,
  # which carries lib.hm.dag — the NixOS lib in this file's own arguments
  # does not.
  home-manager.users.${vars.user} = { lib, ... }: {
    imports = [ inputs.dank-material-shell.homeModules.dank-material-shell ];

    programs.dank-material-shell = {
      enable = true;

      # Launched from the Hyprland autostart instead, alongside the other
      # session daemons. The unit defaults to binding graphical-session.target,
      # which this machine's plain (non-UWSM) Hyprland session never activates
      # — the same trap that stopped ntfy autostarting; see modules/nixos/ntfy.nix.
      systemd.enable = false;

      enableSystemMonitoring = true;   # cpu/mem/temp/disk widgets
      enableVPN = true;                # NetworkManager VPN widget
      enableCalendarEvents = false;    # would pull in khal; we don't use it
      enableAudioWavelength = false;   # cava dependency, not wanted

      # Needed for the "dynamic" theme mode the seed selects — matugen derives
      # the palette from the wallpaper. Every template that would WRITE to a
      # config we manage elsewhere is disabled in the seed above.
      enableDynamicTheming = true;

      # settings.json and session.json are deliberately NOT declared here.
      #
      # The module writes them as read-only /nix/store symlinks, which means
      # DMS's own Settings UI silently cannot save: every change made in the
      # GUI lives in memory only and is lost on the next restart. During a
      # trial that is exactly backwards — tuning the shell by hand is the
      # whole point. So these stay empty (the module then writes no file at
      # all) and the activation below seeds a *writable* copy once, after
      # which the file belongs to DMS.
      settings = { };
      session = { };
    };

    # Seed the settings file once, then get out of the way. Replaces a
    # /nix/store symlink if one is there (migrating from the declarative
    # layout), but never touches a real file — that is DMS's, and overwriting
    # it would throw away exactly the hand-tuning this arrangement exists to
    # keep.
    home.activation.seedDmsSettings =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        target="$HOME/${dmsSettingsPath}"
        if [ ! -e "$target" ] || [ -L "$target" ]; then
          run mkdir -p "$(dirname "$target")"
          run rm -f "$target"
          run cp ${dmsSeedFile} "$target"
          run chmod u+w "$target"
          echo "dms: seeded $target (writable — DMS owns it from here)"
        fi
      '';

    # Workspace app icons come from DMS's icon theme service rather than the
    # Nerd Font glyph table in waybar/config.toml, so it needs a real icon set.
    home.packages = with pkgs; [ papirus-icon-theme ];
  };
}
