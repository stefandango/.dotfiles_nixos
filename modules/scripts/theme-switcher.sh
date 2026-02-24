#!/usr/bin/env bash
# Theme Switcher - applies a theme live to Hyprland, Waybar, Rofi, and SwayNC
# Usage: theme-switcher.sh <theme-file.json>

set -euo pipefail

THEME_FILE="$1"
THEME_DIR="$HOME/.config/theme/themes"
PERSIST_FILE="$HOME/.config/theme/current"

if [[ ! -f "$THEME_FILE" ]]; then
    # Try resolving from theme directory
    THEME_FILE="$THEME_DIR/$1"
fi

if [[ ! -f "$THEME_FILE" ]]; then
    echo "Theme file not found: $1"
    exit 1
fi

# Read theme colors using jq
get() { jq -r ".$1" "$THEME_FILE"; }

BG=$(get bg)
FG=$(get fg)
RED=$(get red)
ORANGE=$(get orange)
YELLOW=$(get yellow)
GREEN=$(get green)
CYAN=$(get cyan)
BLUE=$(get blue)
PURPLE=$(get purple)
WHITE=$(get white)
BLACK=$(get black)
GRAY=$(get gray)
HIGHLIGHT=$(get highlight)
COMMENT=$(get comment)
ACTIVE=$(get active)
INACTIVE=$(get inactive)
TEXT=$(get text)
NAME=$(get name)

# Helper: hex to "R, G, B" string
hex2rgb() {
    local hex="$1"
    printf "%d, %d, %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

RGB_BG=$(hex2rgb "$BG")
RGB_FG=$(hex2rgb "$FG")
RGB_RED=$(hex2rgb "$RED")
RGB_YELLOW=$(hex2rgb "$YELLOW")
RGB_ACTIVE=$(hex2rgb "$ACTIVE")

# ─── 1. Hyprland ───────────────────────────────────────────────────────────────

hyprctl keyword general:col.active_border "rgba(${CYAN}ee) rgba(${GREEN}ee) 45deg"
hyprctl keyword general:col.inactive_border "rgba(${GRAY}aa)"
hyprctl keyword group:col.border_active "rgba(${CYAN}ee)"
hyprctl keyword group:col.border_inactive "rgba(${GRAY}aa)"
hyprctl keyword group:groupbar:col.active "rgb(${BLUE})"
hyprctl keyword group:groupbar:col.inactive "rgb(${GRAY})"
hyprctl keyword group:groupbar:text_color "rgb(ffffff)"
hyprctl keyword misc:background_color "0x${BG}"

# ─── 2. Waybar ─────────────────────────────────────────────────────────────────

cat > "$HOME/.config/waybar/style.css" << WAYBAR_EOF
* {
    border: none;
    border-radius: 0;
    font-family: "MonoLisa Nerd Font", "JetBrainsMono Nerd Font", monospace;
    font-weight: 500;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(${RGB_BG}, 0.85);
    color: #${FG};
    transition-property: background-color;
    transition-duration: 0.3s;
    border-radius: 0;
    margin: 0;
    padding: 0;
}

tooltip {
    background: rgba(${RGB_BG}, 0.95);
    color: #${FG};
    border-radius: 8px;
    border: 2px solid #${ACTIVE};
    padding: 8px;
}

#workspaces {
    padding: 2px 6px;
    margin: 2px 6px;
    background: transparent;
    border: none;
    border-radius: 8px;
}

#workspaces button {
    padding: 4px 8px;
    color: #${TEXT};
    background: transparent;
    border: none;
    border-radius: 6px;
    margin: 0 1px;
    transition: all 0.2s ease;
    font-weight: 500;
    min-width: 28px;
}

#workspaces button.active {
    color: #${FG};
    background: rgba(${RGB_ACTIVE}, 0.6);
    border: none;
    box-shadow: 0 2px 8px rgba(${RGB_ACTIVE}, 0.2);
}

#workspaces button:hover {
    background: rgba(${RGB_FG}, 0.2);
    color: #${FG};
}

#workspaces button.urgent {
    color: #${RED};
    background: rgba(${RGB_RED}, 0.3);
    border: none;
}

#clock,
#custom-weather,
#custom-docker,
#custom-clipboard,
#custom-razerviperbattery,
#custom-disks,
#memory,
#cpu,
#temperature,
#pulseaudio,
#network,
#tray,
#custom-notification,
#custom-logout {
    padding: 4px 8px;
    margin: 2px 3px;
    color: #${FG};
    background: transparent;
    border: none;
    border-radius: 6px;
    transition: all 0.2s ease;
}

#clock:hover,
#custom-weather:hover,
#custom-docker:hover,
#custom-clipboard:hover,
#custom-razerviperbattery:hover,
#custom-disks:hover,
#memory:hover,
#cpu:hover,
#temperature:hover,
#pulseaudio:hover,
#network:hover,
#custom-notification:hover,
#custom-logout:hover {
    background: rgba(${RGB_ACTIVE}, 0.2);
}

#clock {
    color: #${FG};
    font-weight: bold;
    min-width: 80px;
}

#custom-weather {
    color: #${BLUE};
}

#custom-docker {
    color: #${GREEN};
}

#custom-clipboard {
    color: #${PURPLE};
}

#custom-memory {
    color: #${ORANGE};
}

#custom-cpu {
    color: #${YELLOW};
}

#custom-temperature {
    color: #${RED};
}

#temperature.critical {
    color: #${RED};
    background: rgba(${RGB_RED}, 0.2);
}

#pulseaudio {
    color: #${PURPLE};
}

#pulseaudio.muted {
    color: #${GRAY};
}

#network {
    color: #${GREEN};
}

#network.disconnected {
    color: #${RED};
}

#custom-logout {
    color: #${RED};
    font-weight: bold;
}

#custom-logout:hover {
    background: rgba(${RGB_RED}, 0.2);
    border-color: #${RED};
}

#custom-razerviperbattery {
    color: #${YELLOW};
}

#custom-notification {
    color: #${FG};
}

#custom-devserver {
    color: #${CYAN};
}

#custom-tmux {
    color: #${TEXT};
}

#tray {
    padding: 4px 8px;
    background: rgba(${RGB_BG}, 0.8);
    border: 1px solid rgba(${RGB_ACTIVE}, 0.5);
    border-radius: 6px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #${RED};
}

@keyframes submap-pulse {
    0%   { box-shadow: 0 0 4px rgba(${RGB_YELLOW}, 0.4); }
    50%  { box-shadow: 0 0 12px rgba(${RGB_YELLOW}, 0.8); }
    100% { box-shadow: 0 0 4px rgba(${RGB_YELLOW}, 0.4); }
}

@keyframes submap-kill-pulse {
    0%   { box-shadow: 0 0 8px rgba(${RGB_RED}, 0.6); }
    50%  { box-shadow: 0 0 20px rgba(${RGB_RED}, 1.0); }
    100% { box-shadow: 0 0 8px rgba(${RGB_RED}, 0.6); }
}

@keyframes submap-shake {
    0%   { margin-left: 6px; }
    20%  { margin-left: 10px; }
    40%  { margin-left: 2px; }
    60%  { margin-left: 9px; }
    80%  { margin-left: 3px; }
    100% { margin-left: 6px; }
}

#custom-submap {
    color: #${BG};
    font-weight: bold;
    font-size: 14px;
    padding: 4px 14px;
    border-radius: 8px;
    margin: 2px 6px;
}

#custom-submap.window {
    background: linear-gradient(135deg, #${YELLOW}, #${ORANGE});
    animation: submap-pulse 2s ease-in-out infinite;
}

#custom-submap.kill {
    background: #${RED};
    padding: 4px 30px;
    margin: 2px 8px;
    animation: submap-kill-pulse 0.8s ease-in-out infinite, submap-shake 0.4s ease-in-out infinite;
}

#custom-submap.empty {
    padding: 0;
    margin: 0;
}
WAYBAR_EOF

# Reload waybar
pkill waybar 2>/dev/null; sleep 0.5; waybar &disown

# ─── 3. Rofi ───────────────────────────────────────────────────────────────────

cat > "$HOME/.config/rofi/shared/colors.rasi" << ROFI_EOF
* {
    /* Modern glass theme with enhanced transparency */
    background:     rgb(${RGB_BG}, 85%);
    background-alt: rgba(43, 43, 57, 0.7);
    background-hover: rgba(${RGB_ACTIVE}, 0.1);
    background-glass: rgba(${RGB_BG}, 0.95);

    foreground:     rgb(${RGB_FG});
    foreground-dim: rgba(${RGB_FG}, 0.7);

    selected:       rgba(${RGB_ACTIVE}, 0.9);
    selected-hover: rgba(${RGB_ACTIVE}, 0.95);

    border:         rgba(${RGB_ACTIVE}, 0.8);
    border-hover:   rgba(${RGB_ACTIVE}, 1.0);

    active:         rgba(${RGB_ACTIVE}, 0.85);
    urgent:         rgba(${RGB_FG}, 0.9);

    /* Modern accent colors */
    accent:         rgb(${RGB_ACTIVE});
    accent-dim:     rgba(${RGB_ACTIVE}, 0.5);

    /* Shadow effects */
    shadow:         rgba(0, 0, 0, 0.3);
}
ROFI_EOF

# ─── 4. SwayNC ─────────────────────────────────────────────────────────────────

# Derive darker/hover variants from bg
BG_R=$((16#${BG:0:2}))
BG_G=$((16#${BG:2:2}))
BG_B=$((16#${BG:4:2}))
DARKER_R=$(( BG_R + 20 > 255 ? 255 : BG_R + 20 ))
DARKER_G=$(( BG_G + 20 > 255 ? 255 : BG_G + 20 ))
DARKER_B=$(( BG_B + 20 > 255 ? 255 : BG_B + 20 ))
HOVER_R=$(( BG_R + 10 > 255 ? 255 : BG_R + 10 ))
HOVER_G=$(( BG_G + 10 > 255 ? 255 : BG_G + 10 ))
HOVER_B=$(( BG_B + 10 > 255 ? 255 : BG_B + 10 ))

cat > "$HOME/.config/swaync/style.css" << SWAYNC_EOF
@define-color cc-bg rgba(${RGB_BG}, 0.95);
@define-color noti-border-color rgba(255, 255, 255, 0.15);
@define-color noti-bg rgb(${RGB_BG});
@define-color noti-bg-darker rgb(${DARKER_R}, ${DARKER_G}, ${DARKER_B});
@define-color noti-bg-hover rgb(${HOVER_R}, ${HOVER_G}, ${HOVER_B});
@define-color noti-bg-focus rgba(${RGB_BG}, 0.6);
@define-color noti-close-bg rgba(255, 255, 255, 0.1);
@define-color noti-close-bg-hover rgba(255, 255, 255, 0.15);
@define-color text-color rgba(${RGB_FG}, 1);
@define-color text-color-disabled rgb(150, 150, 150);
@define-color bg-selected rgb(${RGB_FG});
@define-color mpris-album-art-overlay rgba(0, 0, 0, 0.55);
@define-color mpris-button-hover rgba(0, 0, 0, 0.50);

* {
  font-family: MonoLisa Nerd Font Semi-Bold;
}

.control-center .notification-row:focus,
.control-center .notification-row:hover {
  opacity: 1;
  background: @noti-bg-darker;
}

.notification-row {
  outline: none;
  margin: 10px;
  padding: 0;
}

.notification {
  background: transparent;
  padding: 0;
  margin: 0px;
}

.notification-content {
  background: @cc-bg;
  padding: 10px;
  border-radius: 5px;
  border: 1px solid #${ACTIVE};
  margin: 0;
}

.notification-default-action {
  margin: 0;
  padding: 0;
  border-radius: 5px;
}

.close-button {
  background: #${RED};
  color: @cc-bg;
  text-shadow: none;
  padding: 0;
  border-radius: 5px;
  margin-top: 5px;
  margin-right: 5px;
}

.close-button:hover {
  box-shadow: none;
  background: #${RED};
  transition: all .15s ease-in-out;
  border: none;
}

.notification-action {
  border: 2px solid #${ACTIVE};
  border-top: none;
  border-radius: 5px;
}

.notification-default-action:hover,
.notification-action:hover {
  color: #${FG};
  background: #${FG};
}

.notification-default-action {
  border-radius: 5px;
  margin: 0px;
}

.notification-default-action:not(:only-child) {
  border-bottom-left-radius: 7px;
  border-bottom-right-radius: 7px;
}

.notification-action:first-child {
  border-bottom-left-radius: 10px;
  background: @noti-bg-hover;
}

.notification-action:last-child {
  border-bottom-right-radius: 10px;
  background: @noti-bg-hover;
}

.inline-reply {
  margin-top: 8px;
}

.inline-reply-entry {
  background: @noti-bg-darker;
  color: @text-color;
  caret-color: @text-color;
  border: 1px solid @noti-border-color;
  border-radius: 5px;
}

.inline-reply-button {
  margin-left: 4px;
  background: @noti-bg;
  border: 1px solid @noti-border-color;
  border-radius: 5px;
  color: @text-color;
}

.inline-reply-button:disabled {
  background: initial;
  color: @text-color-disabled;
  border: 1px solid transparent;
}

.inline-reply-button:hover {
  background: @noti-bg-hover;
}

.body-image {
  margin-top: 6px;
  background-color: #fff;
  border-radius: 5px;
}

.summary {
  font-size: 10px;
  font-weight: 700;
  background: transparent;
  color: rgba(${RGB_FG}, 1);
  text-shadow: none;
}

.time {
  font-size: 10px;
  font-weight: 700;
  background: transparent;
  color: @text-color;
  text-shadow: none;
  margin-right: 18px;
}

.body {
  font-size: 12px;
  font-weight: 400;
  background: transparent;
  color: @text-color;
  text-shadow: none;
}

.control-center {
  background: @cc-bg;
  border: 2px solid #${ACTIVE};
  border-radius: 10px;
}

.control-center-list {
  background: transparent;
}

.control-center-list-placeholder {
  opacity: .5;
}

.floating-notifications {
  background: transparent;
}

.blank-window {
  background: alpha(black, 0.1);
}

.widget-title {
  color: #${FG};
  padding: 0px 10px;
  margin: 10px 10px 5px 10px;
  font-size: 12px;
  border-radius: 5px;
}

.widget-title>button {
  font-size: 10px;
  color: @text-color;
  text-shadow: none;
  background: @noti-bg;
  box-shadow: none;
  border-radius: 5px;
}

.widget-title>button:hover {
  background: #${RED};
  color: @cc-bg;
}

.widget-dnd {
  background: @noti-bg-darker;
  padding: 5px 10px;
  margin: 10px 10px 5px 10px;
  border-radius: 10px;
  font-size: 12px;
  color: #${FG};
}

.widget-dnd>switch {
  border-radius: 10px;
  background: #${FG};
}

.widget-dnd>switch:checked {
  background: #${RED};
  border: 1px solid #${RED};
}

.widget-dnd>switch slider {
  background: @cc-bg;
  border-radius: 10px;
}

.widget-dnd>switch:checked slider {
  background: @cc-bg;
  border-radius: 10px;
}

.widget-label {
  margin: 10px 10px 5px 10px;
}

.widget-label>label {
  font-size: 1rem;
  color: @text-color;
}

.widget-mpris {
  color: @text-color;
  background: @noti-bg-darker;
  padding: 0px 0px;
  margin: 10px 10px 5px 10px;
  border-radius: 5px;
}

.widget-mpris > box > button {
  border-radius: 5px;
}

.widget-mpris-player {
  padding: 0px 0px;
  margin: 5px;
}

.widget-mpris-title {
  font-size: 12px;
}

.widget-mpris-subtitle {
  font-size: 10px;
}

.widget-buttons-grid {
  font-size: 14px;
  padding: 0px;
  margin: 10px 10px 5px 10px;
  border-radius: 5px;
}

.widget-buttons-grid>flowbox>flowboxchild>button {
  margin: 0px;
  background: @cc-bg;
  border-radius: 5px;
  color: @text-color;
}

.widget-buttons-grid>flowbox>flowboxchild>button:hover {
  background: rgba(${RGB_FG}, 1);
  color: @cc-bg;
}

.widget-menubar>box>.menu-button-bar>button {
  border: none;
  background: transparent;
}

.topbar-buttons>button {
  border: none;
  background: transparent;
}

.widget-volume {
  background: @noti-bg-darker;
  padding: 10px;
  margin: 10px 10px 5px 10px;
  border-radius: 5px;
  font-size: x-large;
  color: @text-color;
}

.widget-volume>box>button {
  background: #${ACTIVE};
  border: none;
}

.per-app-volume {
  background-color: @noti-bg;
  padding: 4px 8px 8px;
  margin: 0 8px 8px;
  border-radius: 5px;
}

.widget-backlight {
  background: @noti-bg-darker;
  padding: 5px;
  margin: 10px 10px 5px 10px;
  border-radius: 5px;
  font-size: x-large;
  color: @text-color;
}

trough {
  background: #${FG};
}

highlight{
  background: #${ACTIVE};
}

.power-buttons{
  font-size: 14px;
  padding: 0px;
  margin: 10px 10px 5px 10px;
  border-radius: 5px;
}

.power-buttons>button {
  background: transparent;
  border: none;
}

.power-buttons>button:hover {
  background: @noti-bg-hover;
}

.widget-menubar>box>.menu-button-bar>button{
  border: none;
  background: transparent;
}

.topbar-buttons>button{
  border: none;
  background: transparent;
}

.widget-buttons-grid{
  padding: 8px;
  margin: 8px;
  border-radius: 12px;
  background-color: @noti-bg;
}

.widget-buttons-grid>flowbox>flowboxchild>button{
  background: @noti-bg;
  border-radius: 12px;
}

.widget-buttons-grid>flowbox>flowboxchild>button:hover {
  background: @noti-bg-hover;
}

.powermode-buttons{
  background-color: @noti-bg;
  padding: 8px;
  margin: 8px;
  border-radius: 12px;
}

.powermode-buttons>button {
  background: transparent;
  border: none;
}

.powermode-buttons>button:hover {
  background: @noti-bg-hover;
}
SWAYNC_EOF

# Reload swaync
pkill swaync 2>/dev/null; sleep 0.5; swaync &disown

# ─── 5. Kitty ──────────────────────────────────────────────────────────────────

# Check if theme has kitty colors
if jq -e '.kitty' "$THEME_FILE" > /dev/null 2>&1; then
    KITTY_BG=$(jq -r '.kitty.background' "$THEME_FILE")
    KITTY_FG=$(jq -r '.kitty.foreground' "$THEME_FILE")
    KITTY_CURSOR=$(jq -r '.kitty.cursor' "$THEME_FILE")
    KITTY_SEL_BG=$(jq -r '.kitty.selection_background' "$THEME_FILE")
    KITTY_SEL_FG=$(jq -r '.kitty.selection_foreground' "$THEME_FILE")

    # Build kitty set-colors arguments
    KITTY_COLORS="background=#${KITTY_BG} foreground=#${KITTY_FG} cursor=#${KITTY_CURSOR} selection_background=#${KITTY_SEL_BG} selection_foreground=#${KITTY_SEL_FG}"
    for i in $(seq 0 15); do
        COLOR=$(jq -r ".kitty.color${i}" "$THEME_FILE")
        KITTY_COLORS="${KITTY_COLORS} color${i}=#${COLOR}"
    done

    # Write override config for new kitty windows
    KITTY_CONF="$HOME/.config/kitty/theme-override.conf"
    mkdir -p "$(dirname "$KITTY_CONF")"
    cat > "$KITTY_CONF" << KITTY_EOF
# Generated by theme-switcher — do not edit
background #${KITTY_BG}
foreground #${KITTY_FG}
cursor #${KITTY_CURSOR}
selection_background #${KITTY_SEL_BG}
selection_foreground #${KITTY_SEL_FG}
KITTY_EOF
    for i in $(seq 0 15); do
        COLOR=$(jq -r ".kitty.color${i}" "$THEME_FILE")
        echo "color${i} #${COLOR}" >> "$KITTY_CONF"
    done

    # Apply to all running kitty instances
    for sock in /tmp/kitty-*; do
        if [ -S "$sock" ]; then
            kitty @ --to "unix:${sock}" set-colors $KITTY_COLORS 2>/dev/null || true
        fi
    done
fi

# ─── 6. Persist ────────────────────────────────────────────────────────────────

mkdir -p "$(dirname "$PERSIST_FILE")"
basename "$THEME_FILE" .json > "$PERSIST_FILE"

notify-send "Theme Switched" "$NAME" --app-name="Theme Switcher"
