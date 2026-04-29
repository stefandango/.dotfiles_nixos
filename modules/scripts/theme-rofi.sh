#!/usr/bin/env bash
# Theme Picker — shows themes in rofi with inline color bars rendered via
# Pango markup (rofi -markup-rows). Avoids the rofi 2.0.0 hotkey/icon bug
# (issue #2209) where -show-icons silently no-ops when launched from a WM
# bind, and side-steps the need for PNG cache files entirely.
set -euo pipefail

THEME_DIR="$HOME/.config/theme/themes"
PERSIST_FILE="$HOME/.config/theme/current"

if [[ ! -d "$THEME_DIR" ]]; then
    notify-send "Theme Switcher" "No themes found in $THEME_DIR" --app-name="Theme Switcher"
    exit 1
fi

# Pango treats '&', '<', '>' as XML — escape user content (theme names) so a
# stray ampersand in a future theme can't break the markup.
pango_esc() {
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# Build a row for a theme: padded name + four solid-color blocks. Uses the
# Unicode full block (U+2588) coloured via <span foreground=...>.
make_row() {
    local json="$1" active_marker="$2"
    local name blue green red yellow
    name=$(jq -r '.name' "$json")
    blue=$(jq -r   '.blue   // .fg // "61afef"' "$json")
    green=$(jq -r  '.green  // .fg // "98c379"' "$json")
    red=$(jq -r    '.red    // .fg // "e06c75"' "$json")
    yellow=$(jq -r '.yellow // .fg // "e5c07b"' "$json")

    # 28-char left column for the name keeps the swatches aligned across rows.
    printf '%-28s <span foreground="#%s">█</span><span foreground="#%s">█</span><span foreground="#%s">█</span><span foreground="#%s">█</span>%s\n' \
        "$(pango_esc "$name")" "$blue" "$green" "$red" "$yellow" "$active_marker"
}

CURRENT=""
[[ -f "$PERSIST_FILE" ]] && CURRENT=$(cat "$PERSIST_FILE")

# Stash theme JSON paths in a stable order so we can resolve rofi's selection
# by INDEX rather than round-tripping through text. Avoids parsing whatever
# rofi 2.0.0 returns from a -markup-rows row (it can include the colour
# blocks, leftover spans, etc., which makes name reconstruction brittle).
THEMES=()
SELECTED_ROW=0
ROW=0
for f in "$THEME_DIR"/*.json; do
    THEMES+=("$f")
    [[ "$(basename "$f" .json)" == "$CURRENT" ]] && SELECTED_ROW=$ROW
    ROW=$((ROW + 1))
done

INDEX=$(
    for f in "${THEMES[@]}"; do
        bn=$(basename "$f" .json)
        if [[ "$bn" == "$CURRENT" ]]; then
            make_row "$f" "  <i>active</i>"
        else
            make_row "$f" ""
        fi
    done | rofi -dmenu \
        -p "Theme" \
        -markup-rows \
        -format i \
        -selected-row "$SELECTED_ROW" \
        -theme "$HOME/.config/rofi/launcher.rasi"
)

[[ -z "$INDEX" ]] && exit 0
[[ "$INDEX" =~ ^-?[0-9]+$ ]] || {
    notify-send "Theme Switcher" "Unexpected rofi output: $INDEX" --app-name="Theme Switcher"
    exit 1
}
[[ "$INDEX" -lt 0 || "$INDEX" -ge "${#THEMES[@]}" ]] && exit 0

~/Scripts/theme-switcher.sh "${THEMES[$INDEX]}"
