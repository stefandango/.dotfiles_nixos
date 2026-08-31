{ config, lib, pkgs, inputs, vars, ... }:

# DankMaterialShell: the desktop shell. One Quickshell process owns the bar,
# notifications, launcher, OSD, lock screen, polkit agent and wallpaper — it
# replaced a waybar + rofi + swaync + hyprlock/hypridle stack (in git history
# up to the "Collapse the desktop shell onto DMS" commit if it is ever wanted
# back).
#
# It is launched from the Hyprland autostart in ./hyprland.nix, not systemd —
# see the note on systemd.enable below.
#
# Nothing may reintroduce a package that ships a D-Bus activation file for
# org.freedesktop.Notifications: activation bypasses module imports entirely,
# and whichever daemon wins the name race owns every notification for the
# session. That is exactly how swaync kept stealing them during the trial.

let
  # ── Seed configuration ────────────────────────────────────────────────────
  # Captured from a live session with `dms ipc call settings dump` after
  # hand-tuning, then folded back in here. This is only the STARTING state:
  # the activation script writes it once and DMS owns the file afterwards, so
  # re-dump and update this block when the look settles again.
  dmsSeedSettings = {
    configVersion = 16;

    # matugen derives the whole palette from the wallpaper, and every app in
    # Phase 4 follows it. `scheme-neutral` is the reason that is liveable:
    # the default `scheme-tonal-spot` pulled a strong wallpaper hue through
    # every surface (bg #0f1417, primary #8ad0ee off ships_at_sea.png),
    # where neutral lands on bg #121314 / primary #bac9d1 -- within a hair of
    # the Graphite palette this replaced. `scheme-monochrome` is the next
    # step down if even that reads as too much colour.
    #
    # Note this does NOT mute the dank16 ANSI ramp: that is generated from
    # the primary independent of the M3 scheme, so it stays saturated
    # (red #f06c96, green #68d174). Hence kitty keeps a static ramp -- see
    # modules/nixos/matugen.nix.
    currentThemeName = "dynamic";
    currentThemeCategory = "dynamic";
    matugenScheme = "scheme-neutral";

    cornerRadius = 12;
    popupTransparency = 0.96;
    m3ElevationEnabled = false;
    barElevationEnabled = false;
    systemTrayIconTintMode = "monochrome";

    fontFamily = "Inter SemiBold";
    monoFontFamily = "MonoLisa Nerd Font";
    fontWeight = 600;

    # Popouts and modals open faster than stock. Hyprland's own layer
    # animation is disabled for dms:* namespaces (see hyprland.nix), so these
    # are the only curve on those surfaces.
    syncComponentAnimationSpeeds = false;
    popoutAnimationSpeed = 4;
    popoutCustomAnimationDuration = 120;
    modalAnimationSpeed = 4;
    modalCustomAnimationDuration = 120;

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
    # No *SuspendTimeout keys: DMS discards them on load (they are not
    # properties), and this host disables Suspend/Hibernate outright in
    # systemd.sleep.settings anyway.
    acLockTimeout = 600;
    acMonitorTimeout = 660;
    batteryLockTimeout = 600;
    batteryMonitorTimeout = 660;
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
    #
    # The dankscale plugin was tried here and reverted: it exposes more
    # (exit nodes, routes, DNS, account switching) but the built-in reads
    # better for day-to-day use. If it is ever reconsidered, note that Control
    # Center plugin ids are "plugin_" ++ the plugin id — NOT the bare id used
    # in barConfigs — and a plugin only appears here if its widget defines
    # ccWidgetIcon (Modules/ControlCenter/Models/WidgetModel.qml).
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

    # DMS ships matugen templates that write theme files for other apps. Only
    # one writer per file is allowed, so each of these is either DMS's job or
    # ours (via ~/.config/matugen/config.toml, see modules/nixos/matugen.nix).
    #
    # GTK is DMS's: scripts/gtk.sh does more than render a template -- it
    # copies adw-gtk3 out of the read-only store into ~/.local/share/themes
    # and splices the colours into the theme's own gtk.css. Reimplementing
    # that would be pure duplication.
    matugenTemplateGtk = true;

    # Ours, because DMS's version would also rewrite the 16 ANSI colours from
    # dank16, which stays saturated regardless of matugenScheme. Our template
    # takes the surface roles and keeps a muted static ramp.
    matugenTemplateKitty = false;

    # Hyprland's borders are a gradient built in hyprland.nix and reapplied at
    # runtime by setBorder(); DMS's template writes a flat col.active_border
    # that setBorder would immediately overwrite, and it has no notion of the
    # submap state colour. Left to Nix.
    matugenTemplateHyprland = false;

    # Qt inherits GTK3 via QT_QPA_PLATFORMTHEME=gtk3, so there is nothing for
    # qt5ct/qt6ct to do -- and neither is installed.
    matugenTemplateQt5ct = false;
    matugenTemplateQt6ct = false;
    matugenTemplateQtengine = false;

    # Neovim lives in its own repo (github:stefandango/LazyVim-Config) and
    # keeps its own colourscheme (kanagawa) on purpose -- editor syntax
    # highlighting wants a palette designed for it, not one derived from a
    # wallpaper.
    matugenTemplateNeovim = false;

    # Compositors we do not run.
    matugenTemplateNiri = false;
    matugenTemplateMangowc = false;

    # Left at their defaults (true) and written today: Zed, Vencord, and the
    # KDE colour schemes. Those apps have no competing writer, so letting the
    # shell theme them is the whole point of unifying on matugen.
    matugenTemplateFirefox = false;
    matugenTemplateZenBrowser = false;
    matugenTemplateVscode = false;

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
      #
      # Everything before "systemTray" is a PLUGIN, not a built-in, and DMS
      # renders nothing for an id it cannot resolve. All but one are restored
      # from the lockfile by `~/Scripts/dmsplugins`; `nixosUpdates` is the
      # exception — it is ours, and ships declaratively via the environment.etc
      # entry at the bottom of this file, so it is there from the first switch.
      #
      # The first two replace six built-in widgets that used to sit here:
      #   systemMonitorPlus → diskUsage + memUsage + cpuUsage + cpuTemp
      #   amdGpuMonitor     → gpuTemp, plus VRAM/power/per-process detail
      # `clipboard` is gone as well: SUPER+Y already opens the clipboard, and
      # the spotlight has the `cb` trigger from builtInPluginSettings below.
      #
      # The rest close gaps waybar had and DMS's built-in set does not cover:
      #   dankRazer     → the old custom/razerviperbattery module. Needs the Go
      #                   helper its build.sh compiles — dmsplugins runs that.
      #   ddcBrightness → brightness over DDC/CI. The built-in brightnessSlider
      #                   drives a backlight class this desktop does not have;
      #                   the LG only responds on i2c (see ddcutil notes).
      #   nixosUpdates  → the old custom/updates module: days behind nixpkgs,
      #                   with the package diff behind a click. See the
      #                   environment.etc entry below for why not `systemUpdate`.
      # Its manifest claims control-center too, but the widget never defines
      # ccWidgetIcon, which is what WidgetModel.qml actually gates on — so
      # dankRazer is bar-only in practice regardless of that capability.
      #
      # Bare strings are fine here — DMS normalises them to
      # { id, enabled = true } on load (Common/settings/Lists.qml).
      rightWidgets = [
        "systemMonitorPlus" "amdGpuMonitor" "claudeCodeUsage"
        "dankRazer" "ddcBrightness" "nixosUpdates"
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

  # Installing a plugin does not enable it: `dms plugins install` only git-clones
  # into ~/.config/DankMaterialShell/plugins, while the enabled flag lives in a
  # separate plugin_settings.json that DMS normally writes from the Settings UI
  # (Services/PluginService.qml enablePlugin()). Seeding it here means a fresh
  # machine needs one command — `dmsplugins` — rather than that plus four toggles.
  #
  # Entries for a plugin that is not installed yet are harmless: DMS just carries
  # the flag until the plugin appears, at which point it loads enabled.
  dmsPluginSettingsFile = pkgs.writeText "dms-plugin-settings-seed.json"
    (builtins.toJSON {
      systemMonitorPlus.enabled = true;   # bar: disk + mem + cpu + cpu temp
      amdGpuMonitor.enabled = true;       # bar: gpu usage/VRAM/temp/power
      claudeCodeUsage.enabled = true;     # bar: Claude Code token usage
      dankRazer.enabled = true;           # bar: Viper Ultimate battery/DPI/lighting
      ddcBrightness.enabled = true;       # bar: DDC/CI brightness for the LG
      wallpaperCarousel.enabled = true;   # daemon: SUPER+SHIFT+W overlay
      nixosUpdates.enabled = true;        # bar: days behind nixpkgs (ships via /etc)
    });

  dmsPluginSettingsPath = ".config/DankMaterialShell/plugin_settings.json";
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
        seedDms() {
          local src="$1" target="$HOME/$2"
          if [ ! -e "$target" ] || [ -L "$target" ]; then
            run mkdir -p "$(dirname "$target")"
            run rm -f "$target"
            run cp "$src" "$target"
            run chmod u+w "$target"
            echo "dms: seeded $target (writable — DMS owns it from here)"
          fi
        }
        seedDms ${dmsSeedFile} ${dmsSettingsPath}
        seedDms ${dmsPluginSettingsFile} ${dmsPluginSettingsPath}
      '';

    # Workspace app icons come from DMS's icon theme service rather than the
    # Nerd Font glyph table in waybar/config.toml, so it needs a real icon set.
    home.packages = with pkgs; [ papirus-icon-theme ];
  };

  # The NixOS update indicator waybar used to carry, as a DMS plugin.
  #
  # Not the built-in `systemUpdate` widget: that is gated on
  # SystemUpdateService.sysupdateAvailable, whose backend only knows
  # pacman/paru/yay (Services/SystemUpdateService.qml:41), and
  # SettingsData.updaterCustomCommand overrides only the *upgrade* command,
  # never the check — so there is no seam to teach it about nix.
  #
  # It ships through /etc rather than ~/.config/DankMaterialShell/plugins
  # because `dmsplugins sync` runs `dms plugins restore --prune`, which deletes
  # every plugin in the user directory the lockfile does not name — and that
  # lockfile records git remotes, which a hand-written plugin does not have.
  # DMS watches both directories (Services/PluginService.qml:22-26) and loads
  # them identically; a user-directory plugin shadows a system one but never
  # the reverse, and the CLI refuses to mutate the system half at all.
  # Nothing is ever written back into a plugin directory — settings go to
  # plugin_settings.json and per-plugin state to ~/.local/state — so a
  # read-only store symlink costs nothing here.
  #
  # The widget renders `~/Scripts/nixupdates --json` and owns no logic of its
  # own; that script is installed from ./scripts.nix and is shared with the
  # waybar path.
  environment.etc."xdg/quickshell/dms-plugins/nixosUpdates".source =
    ./dms/plugins/nixosUpdates;
}
