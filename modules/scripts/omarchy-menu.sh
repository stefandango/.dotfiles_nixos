#!/usr/bin/env bash
# Unified rofi-driven menu — single entry point (Super+Alt+Space) for the
# things you'd otherwise need to remember individual keybinds for.
# Inspired by Omarchy's omarchy-menu, kept thin so most actions delegate to
# scripts that already exist in ~/Scripts.
set -euo pipefail

ROFI_THEME="$HOME/.config/rofi/launcher.rasi"
SCRIPTS="$HOME/Scripts"

# Show a rofi picker. Args: prompt, then one entry per remaining arg.
# Returns the selected entry on stdout, empty if Esc.
pick() {
    local prompt="$1"; shift
    printf '%s\n' "$@" | rofi -dmenu \
        -p "$prompt" \
        -markup-rows \
        -theme "$ROFI_THEME" \
        -theme-str '
            mainbox  { children: [ "inputbar", "listview" ]; }
            window   { width: 600px; }
            listview { lines: 8; fixed-height: false; }
        '
}

# ---- Top-level menu --------------------------------------------------------
main_menu() {
    local sel
    sel=$(pick "Omarchy" \
        "󰏖  Install" \
        "󰧧  Remove" \
        "󰟾  Style" \
        "󰄀  Capture" \
        "󰒓  System" \
        "󰐥  Power")

    case "$sel" in
        *Install*) install_menu ;;
        *Remove*)  remove_menu ;;
        *Style*)   style_menu ;;
        *Capture*) capture_menu ;;
        *System*)  system_menu ;;
        *Power*)   exec "$HOME/.config/rofi/powermenu.sh" ;;
        *)         exit 0 ;;
    esac
}

# ---- Install --------------------------------------------------------------
install_menu() {
    local sel
    sel=$(pick "Install" \
        "←  Back" \
        "󰖟  Web App")
    case "$sel" in
        *Back*)    main_menu ;;
        *Web*App*) exec "$SCRIPTS/omarchy-webapp-install.sh" ;;
        *)         exit 0 ;;
    esac
}

# ---- Remove ---------------------------------------------------------------
remove_menu() {
    local sel
    sel=$(pick "Remove" \
        "←  Back" \
        "󰖟  Web App")
    case "$sel" in
        *Back*)    main_menu ;;
        *Web*App*) exec "$SCRIPTS/omarchy-webapp-remove.sh" ;;
        *)         exit 0 ;;
    esac
}

# ---- Style ----------------------------------------------------------------
style_menu() {
    local sel
    sel=$(pick "Style" \
        "←  Back" \
        "󰸌  Theme" \
        "󰸉  Random wallpaper")
    case "$sel" in
        *Back*)      main_menu ;;
        *Theme*)     exec "$SCRIPTS/theme-rofi.sh" ;;
        *wallpaper*) exec "$SCRIPTS/awww_random.sh" ;;
        *)           exit 0 ;;
    esac
}

# ---- Capture --------------------------------------------------------------
capture_menu() {
    local sel ts out
    sel=$(pick "Capture" \
        "←  Back" \
        "󰒅  Region (drag to select)" \
        "󰖯  Active window" \
        "󰍹  Whole screen")
    ts=$(date +%Y-%m-%dT%H%M%S)
    out="$HOME/Pictures/$ts.png"
    case "$sel" in
        *Back*)    main_menu ;;
        *Region*)  grimblast --notify --freeze --wait 1 copysave area "$out" ;;
        *window*)  grimblast --notify copysave active "$out" ;;
        *screen*)  grimblast --notify copysave screen "$out" ;;
        *)         exit 0 ;;
    esac
}

# ---- System ---------------------------------------------------------------
system_menu() {
    local sel
    sel=$(pick "System" \
        "←  Back" \
        "󰚰  Update flake (nixup)" \
        "󰍡  Cheatsheet" \
        "󰋖  Network info")
    case "$sel" in
        *Back*)        main_menu ;;
        *Update*)      kitty --hold -- "$SCRIPTS/nixup" ;;
        *Cheatsheet*)  exec "$SCRIPTS/cheatsheet.sh" ;;
        *Network*)     kitty --hold -- "$SCRIPTS/netinfo" ;;
        *)             exit 0 ;;
    esac
}

main_menu
