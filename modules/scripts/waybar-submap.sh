#!/usr/bin/env bash
# Waybar custom module: listens to hyprland submap changes via socket
# Waybar manages lifecycle - script exits when waybar kills it

trap 'exit 0' TERM INT

socat=$(command -v socat || echo "/run/current-system/sw/bin/socat")
"$socat" -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r line; do
    case "$line" in
        "submap>>window")
            echo '{"text": "󰩨 window", "class": "window", "tooltip": "Window management mode"}'
            ;;
        "submap>>kill")
            echo '{"text": "󰚌 kill?", "class": "kill", "tooltip": "Press Q or Enter to kill, Escape to cancel"}'
            ;;
        "submap>>")
            echo '{"text": "", "class": "empty"}'
            ;;
    esac
done
