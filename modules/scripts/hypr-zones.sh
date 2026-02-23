#!/usr/bin/env bash
# hypr-zones.sh - Rofi-based ultrawide zone manager (tiling-based)
# Uses splitratio exact to resize within the dwindle tiling tree.
# Usage: hypr-zones.sh          (opens rofi picker)
#        hypr-zones.sh <zone>   (apply zone directly)

get_window_side() {
    # Determine if the active window is on the left or right side of its split
    local win_json mon_json
    win_json=$(hyprctl activewindow -j)
    local win_x win_w
    win_x=$(echo "$win_json" | jq -r '.at[0]')
    win_w=$(echo "$win_json" | jq -r '.size[0]')
    local win_center_x=$(( win_x + win_w / 2 ))

    local monitor_name
    monitor_name=$(echo "$win_json" | jq -r '.monitor')
    mon_json=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$monitor_name\")")
    local mon_x mon_w
    mon_x=$(echo "$mon_json" | jq -r '.x')
    mon_w=$(echo "$mon_json" | jq -r '.width')
    local mon_center_x=$(( mon_x + mon_w / 2 ))

    if [ "$win_center_x" -lt "$mon_center_x" ]; then
        echo "left"
    else
        echo "right"
    fi
}

swap_and_resize() {
    local direction="$1" ratio="$2"
    hyprctl dispatch swapwindow "$direction"
    sleep 0.1
    hyprctl dispatch splitratio exact "$ratio"
}

apply_zone() {
    local zone="$1"

    case "$zone" in
        even-split)
            hyprctl dispatch splitratio exact 1.0
            ;;
        left-third)
            local side
            side=$(get_window_side)
            if [ "$side" = "right" ]; then
                swap_and_resize l 0.667
            else
                hyprctl dispatch splitratio exact 0.667
            fi
            ;;
        right-third)
            local side
            side=$(get_window_side)
            if [ "$side" = "left" ]; then
                swap_and_resize r 1.333
            else
                hyprctl dispatch splitratio exact 1.333
            fi
            ;;
        left-half)
            local side
            side=$(get_window_side)
            if [ "$side" = "right" ]; then
                swap_and_resize l 1.0
            else
                hyprctl dispatch splitratio exact 1.0
            fi
            ;;
        right-half)
            local side
            side=$(get_window_side)
            if [ "$side" = "left" ]; then
                swap_and_resize r 1.0
            else
                hyprctl dispatch splitratio exact 1.0
            fi
            ;;
        left-twothirds)
            local side
            side=$(get_window_side)
            if [ "$side" = "right" ]; then
                swap_and_resize l 1.333
            else
                hyprctl dispatch splitratio exact 1.333
            fi
            ;;
        right-twothirds)
            local side
            side=$(get_window_side)
            if [ "$side" = "left" ]; then
                swap_and_resize r 0.667
            else
                hyprctl dispatch splitratio exact 0.667
            fi
            ;;
        center-twothirds)
            # Float the window at 2/3 width, centered on monitor
            local win_json floating win_addr mon_json
            local mon_x mon_y mon_w mon_h reserved_top
            local target_w target_h target_x target_y
            win_json=$(hyprctl activewindow -j)
            floating=$(echo "$win_json" | jq -r '.floating')
            win_addr=$(echo "$win_json" | jq -r '.address')
            local monitor_name
            monitor_name=$(echo "$win_json" | jq -r '.monitor')
            mon_json=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$monitor_name\")")
            mon_x=$(echo "$mon_json" | jq -r '.x')
            mon_y=$(echo "$mon_json" | jq -r '.y')
            mon_w=$(echo "$mon_json" | jq -r '.width')
            mon_h=$(echo "$mon_json" | jq -r '.height')
            reserved_top=$(echo "$mon_json" | jq -r '.reserved[1]')
            target_w=$(( mon_w * 2 / 3 ))
            target_h=$(( (mon_h - reserved_top) * 9 / 10 ))
            target_x=$(( mon_x + (mon_w - target_w) / 2 ))
            target_y=$(( mon_y + reserved_top + (mon_h - reserved_top - target_h) / 2 ))
            [ "$floating" = "false" ] && hyprctl dispatch togglefloating "address:$win_addr" && sleep 0.2
            hyprctl dispatch resizewindowpixel "exact $target_w $target_h,address:$win_addr"
            sleep 0.1
            hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$win_addr"
            ;;
        *)
            echo "Unknown zone: $zone"
            return 1 ;;
    esac
}

# Direct zone argument — skip rofi
if [ -n "$1" ]; then
    apply_zone "$1"
    exit $?
fi

# Save active window address before rofi steals focus
active_addr=$(hyprctl activewindow -j | jq -r '.address')

# Build rofi menu
menu=(
    "⊞  Even Split           [█ █]"
    "◧  Left Third           [█░░]"
    "◨  Right Third          [░░█]"
    "◧  Left Half            [██░░]"
    "◨  Right Half           [░░██]"
    "◧  Left Two-Thirds      [██░]"
    "◨  Right Two-Thirds     [░██]"
    "⊟  Center Two-Thirds    [░██░]"
)

chosen=$(printf '%s\n' "${menu[@]}" | rofi -dmenu -theme ~/.config/rofi/zones.rasi -p "Zone")

[ -z "$chosen" ] && exit 0

# Restore focus to the original window before applying zone
hyprctl dispatch focuswindow "address:${active_addr}"
sleep 0.15

# Map selection to zone name
case "$chosen" in
    *"Even Split"*)         apply_zone "even-split" ;;
    *"Left Third"*)         apply_zone "left-third" ;;
    *"Right Third"*)        apply_zone "right-third" ;;
    *"Left Half"*)          apply_zone "left-half" ;;
    *"Right Half"*)         apply_zone "right-half" ;;
    *"Left Two-Thirds"*)    apply_zone "left-twothirds" ;;
    *"Right Two-Thirds"*)   apply_zone "right-twothirds" ;;
    *"Center Two-Thirds"*)  apply_zone "center-twothirds" ;;
esac
