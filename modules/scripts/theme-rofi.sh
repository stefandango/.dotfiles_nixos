#!/usr/bin/env bash
# Theme Picker - shows available themes in rofi and applies the selected one
# Usage: theme-rofi.sh

THEME_DIR="$HOME/.config/theme/themes"
PERSIST_FILE="$HOME/.config/theme/current"

if [[ ! -d "$THEME_DIR" ]]; then
    notify-send "Theme Switcher" "No themes found in $THEME_DIR" --app-name="Theme Switcher"
    exit 1
fi

# Get current theme for highlighting
CURRENT=""
if [[ -f "$PERSIST_FILE" ]]; then
    CURRENT=$(cat "$PERSIST_FILE")
fi

# Build theme list: "name (filename)" with current marked
ENTRIES=""
SELECTED_ROW=0
ROW=0
for f in "$THEME_DIR"/*.json; do
    basename=$(basename "$f" .json)
    name=$(jq -r '.name' "$f")
    if [[ "$basename" == "$CURRENT" ]]; then
        ENTRIES+="${name} [active]\n"
        SELECTED_ROW=$ROW
    else
        ENTRIES+="${name}\n"
    fi
    ROW=$((ROW + 1))
done

# Show rofi picker
CHOICE=$(echo -e "$ENTRIES" | rofi -dmenu -p "Theme" -selected-row "$SELECTED_ROW" -theme ~/.config/rofi/launcher.rasi)

if [[ -z "$CHOICE" ]]; then
    exit 0
fi

# Strip [active] marker if present
CHOICE="${CHOICE% \[active\]}"

# Find matching theme file by name
for f in "$THEME_DIR"/*.json; do
    name=$(jq -r '.name' "$f")
    if [[ "$name" == "$CHOICE" ]]; then
        ~/Scripts/theme-switcher.sh "$f"
        exit 0
    fi
done

notify-send "Theme Switcher" "Theme not found: $CHOICE" --app-name="Theme Switcher"
