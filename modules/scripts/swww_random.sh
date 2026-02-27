#!/bin/sh

# Randomly cycle through wallpapers from ~/Pictures/highres at regular intervals

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/highres"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_STEP=2

# This controls (in seconds) when to switch to the next image
INTERVAL=300

while true; do
    for monitor in $(swww query | awk -F: '{gsub(/^ +| +$/, "", $2); print $2}'); do
        img=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
        if [[ -n "$img" ]]; then
            echo "$monitor $img"
            swww img "$img" -o "$monitor" --transition-type random
        fi
    done
    sleep $INTERVAL
done
