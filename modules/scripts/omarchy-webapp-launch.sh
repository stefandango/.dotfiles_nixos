#!/usr/bin/env bash
# Launch a Firefox PWA by name (case-insensitive) — resolves the ULID at run
# time so reinstalls don't break the Hyprland binds that call this.
# Usage: omarchy-webapp-launch.sh "ChatGPT"
set -euo pipefail

NAME="${1:?usage: omarchy-webapp-launch.sh <web-app-name>}"

if ! command -v firefoxpwa >/dev/null 2>&1; then
    notify-send "Web App" "firefoxpwa not on PATH" --urgency=critical --app-name="Omarchy"
    exit 1
fi

# `firefoxpwa profile list` rows: "- <Name>: <manifest-url> (<ULID>)"
ID=$(firefoxpwa profile list 2>/dev/null \
    | sed -nE 's/^- (.+): .* \(([0-9A-Z]{26})\)$/\1\t\2/p' \
    | awk -F'\t' -v target="$NAME" 'tolower($1)==tolower(target) {print $2; exit}')

if [[ -z "$ID" ]]; then
    notify-send "Web App not installed" \
        "$NAME — install via Super+Alt+Space → Install → Web App" \
        --urgency=normal --app-name="Omarchy"
    exit 1
fi

exec firefoxpwa site launch "$ID"
