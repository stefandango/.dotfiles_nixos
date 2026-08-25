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

  defaultTheme = "graphite";
in
{
  home-manager.users.${vars.user} = {
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

      # We pin a static palette, so matugen never needs to derive one from the
      # wallpaper. Left on only because DMS uses the same code path to apply
      # our custom theme; every template that would WRITE to a config we manage
      # elsewhere is disabled below.
      enableDynamicTheming = true;

      session = {
        isLightMode = false;
      };

      settings = {
        currentThemeName = "custom";
        customThemeFile = "${dmsThemes}/${defaultTheme}.json";

        # Flatten the Material look toward the flat/terminal aesthetic:
        # elevation shadows are most of what reads as "Material".
        cornerRadius = 12;
        m3ElevationEnabled = false;

        # waybar drew Roman numerals plus per-app icons via
        # hyprland-autoname-workspaces. Without these two, DMS renders the
        # active workspace as an empty coloured lozenge with nothing in it,
        # which is the single most unfinished-looking thing on the bar.
        showWorkspaceIndex = true;
        showWorkspaceApps = true;
        maxWorkspaceIcons = 4;

        fontFamily = "Inter";
        monoFontFamily = "MonoLisa Nerd Font";

        # Tooltips/popups sat on rgba(bg, 0.95) under waybar; keep that.
        popupTransparency = 0.96;

        # Idle and lock. DMS owns both now that hypridle is not started, and
        # every one of its timeouts defaults to 0 = disabled — so without these
        # the machine never locks and never blanks. Values reproduce the old
        # hypridle listeners exactly (lock at 600s, monitors off at 660s).
        # Suspend stays 0: this host disables Suspend/Hibernate outright in
        # systemd.sleep.settings, so arming it here would only fail loudly.
        acLockTimeout = 600;
        acMonitorTimeout = 660;
        acSuspendTimeout = 0;
        batteryLockTimeout = 600;
        batteryMonitorTimeout = 660;
        batterySuspendTimeout = 0;

        # Matches hypridle's `before_sleep_cmd = loginctl lock-session`.
        lockBeforeSuspend = true;

        # Control Center contents. This list REPLACES the defaults, so the
        # stock entries have to be repeated. builtin_tailscale is not in the
        # defaults at all, which is why Tailscale appears nowhere until it is
        # named here.
        controlCenterWidgets = [
          { id = "volumeSlider";     enabled = true; width = 50; }
          { id = "brightnessSlider"; enabled = true; width = 50; }
          { id = "wifi";             enabled = true; width = 50; }
          { id = "bluetooth";        enabled = true; width = 50; }
          { id = "builtin_tailscale"; enabled = true; width = 100; }
          { id = "audioOutput";      enabled = true; width = 50; }
          { id = "audioInput";       enabled = true; width = 50; }
          { id = "doNotDisturb";     enabled = true; width = 50; }
          { id = "idleInhibitor";    enabled = true; width = 50; }
          { id = "nightMode";        enabled = true; width = 50; }
          { id = "darkMode";         enabled = true; width = 50; }
        ];

        # DMS ships matugen templates that write theme files for other apps.
        # Hyprland colours come from theme-switcher.sh via hyprctl, and kitty
        # from theme-override.conf — letting DMS also write them would mean two
        # writers for one file. GTK/Qt are pinned static in theme/theming.nix.
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

        # Mirrors the current waybar layout as closely as DMS's widget set
        # allows. Still missing native equivalents (candidates for plugins):
        # docker, llama, devserver, tmux, razer battery, focus mode, game mode,
        # and the submap indicator.
        barConfigs = [{
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;                     # top
          screenPreferences = [ "all" ];
          leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
          centerWidgets = [ "music" "clock" "weather" ];
          rightWidgets = [
            "systemUpdate" "clipboard"
            "diskUsage" "memUsage" "cpuUsage" "cpuTemp" "gpuTemp"
            "vpn" "systemTray" "notificationButton"
            "controlCenterButton" "powerMenuButton"
          ];
          # First attempt gave every widget its own card on a transparent bar,
          # which scattered the right-hand side into a dozen disconnected pills.
          # One cohesive floating bar reads far better: the bar itself carries
          # the surface, and the widgets sit flat inside it.
          noBackground = false;
          transparency = 0.85;
          widgetTransparency = 0.0;     # widgets flat — no card per widget
          widgetOutlineEnabled = false; # outlines on every pill were pure noise

          # Float it off the screen edges so the rounded corners actually read
          # as corners instead of being clipped by the edge of the display.
          attachToScreenEdge = false;
          barLengthPadding = 14;
          bottomGap = 6;

          spacing = 2;
          innerPadding = 6;
          widgetPadding = 9;
          squareCorners = false;
        }];
      };
    };

    # Workspace app icons come from DMS's icon theme service rather than the
    # Nerd Font glyph table in waybar/config.toml, so it needs a real icon set.
    home.packages = with pkgs; [ papirus-icon-theme ];
  };
}
