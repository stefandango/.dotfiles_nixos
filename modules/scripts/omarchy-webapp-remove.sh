#!/usr/bin/env bash
# Pick an installed Firefox PWA from rofi and uninstall it via firefoxpwa.
# Usage: omarchy-webapp-remove.sh
set -euo pipefail

ROFI_THEME="$HOME/.config/rofi/launcher.rasi"

if ! command -v firefoxpwa >/dev/null 2>&1; then
    notify-send "Omarchy Web App" "firefoxpwa not on PATH — run nixswitch?" \
        --app-name="Omarchy" --urgency=critical
    exit 1
fi

# `firefoxpwa profile list` lists every profile and, under each, lines like
#   - <Name>: <manifest-url> (<ULID>)
# Extract those into TSV of ULID<TAB>Name for the picker.
LIST=$(firefoxpwa profile list 2>/dev/null) || {
    notify-send "Omarchy Web App" "Could not query firefoxpwa" \
        --app-name="Omarchy" --urgency=critical
    exit 1
}

ENTRIES=$(printf '%s\n' "$LIST" \
    | sed -nE 's/^- (.+): .* \(([0-9A-Z]{26})\)$/\2\t\1/p')

if [[ -z "$ENTRIES" ]]; then
    notify-send "Omarchy Web App" "No web apps installed" --app-name="Omarchy"
    exit 0
fi

pango_esc() {
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

COUNT=$(printf '%s\n' "$ENTRIES" | wc -l)
CHOICE=$(printf '%s\n' "$ENTRIES" \
    | cut -f2 \
    | rofi -dmenu \
        -p "Pick web app" \
        -mesg "<b>Uninstall a web app</b> — $COUNT installed. Esc to cancel." \
        -markup-rows \
        -theme "$ROFI_THEME" \
        -theme-str '
            mainbox  { children: [ "message", "inputbar", "listview" ]; }
            window   { width: 600px; }
            message  { padding: 12px 4px; }
            textbox  { markup: true; }
        ')
[[ -z "$CHOICE" ]] && exit 0

ID=$(printf '%s\n' "$ENTRIES" | awk -F'\t' -v name="$CHOICE" '$2==name {print $1; exit}')
if [[ -z "$ID" ]]; then
    notify-send "Omarchy Web App" "Could not resolve $CHOICE" \
        --app-name="Omarchy" --urgency=critical
    exit 1
fi

# Confirm before destroying the entry.
CONFIRM=$(printf '%s\n%s\n' '✗  Uninstall' '✓  Keep' | rofi -dmenu \
    -p "Confirm" \
    -mesg "<b>Uninstall $(pango_esc "$CHOICE")?</b>
<i>This removes the desktop entry and the per-app Firefox profile.</i>" \
    -markup-rows \
    -theme "$ROFI_THEME" \
    -theme-str '
        mainbox  { children: [ "message", "inputbar", "listview" ]; }
        window   { width: 600px; }
        listview { lines: 2; fixed-height: false; }
        message  { padding: 12px 4px; }
        textbox  { markup: true; }
    ')

case "$CONFIRM" in
    *Uninstall*) ;;
    *) notify-send "Cancelled" "$CHOICE was kept" --app-name="Omarchy"; exit 0 ;;
esac

if firefoxpwa site uninstall --quiet "$ID"; then
    notify-send "✓ $CHOICE removed" "Desktop entry and profile deleted" --app-name="Omarchy"
else
    notify-send "✗ Removal failed" "$CHOICE — see terminal output" \
        --app-name="Omarchy" --urgency=critical
    exit 1
fi
