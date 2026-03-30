#!/usr/bin/env bash
# Anarchy Online Triple Instance Launcher for NixOS + Hyprland
#
# Usage:
#   ao-launch.sh           # Launch all 3 instances
#   ao-launch.sh stop      # Kill all instances
#   ao-launch.sh 1         # Launch only instance 1 (Adventurer)
#   ao-launch.sh 2         # Launch only instance 2 (Fixer)
#   ao-launch.sh 3         # Launch only instance 3 (Bureaucrat)
#   ao-launch.sh setup     # Create wine prefixes and show setup instructions

AO_BASE="$HOME/Games"
AO_DIR="drive_c/Funcom/Anarchy Online"

# Layout for 5120x2160 ultrawide:
#  Workspace 8: Adventurer fullscreen
#  Workspace 9: Fixer (left) + Bureaucrat (right) side by side
INSTANCES=(
    "Adventurer:ao-adventurer:0-3:5120 2160:0 0:8"
    "Fixer:ao-fixer:4-7:2560 2160:0 0:9"
    "Bureaucrat:ao-bureaucrat:8-11:2560 2160:2560 0:9"
)

# Track addresses of windows we've already claimed
CLAIMED_ADDRS=()

setup_prefixes() {
    echo "=== Anarchy Online Multibox Setup ==="
    echo ""
    for inst in "${INSTANCES[@]}"; do
        IFS=':' read -r name dir _ _ _ <<< "$inst"
        prefix="$AO_BASE/$dir"
        if [ -d "$prefix" ]; then
            echo "  [exists] $prefix"
        else
            echo "  [creating] $prefix"
            mkdir -p "$prefix"
            WINEPREFIX="$prefix" WINEARCH=win64 wine wineboot 2>/dev/null
            echo "  [installing deps] $name"
            WINEPREFIX="$prefix" winetricks d3dcompiler_43 d3dx9 2>/dev/null
        fi
    done
    echo ""
    echo "Next steps:"
    echo "  1. Copy your working AO install to each prefix:"
    for inst in "${INSTANCES[@]}"; do
        IFS=':' read -r name dir _ _ _ <<< "$inst"
        echo "     cp -r ~/Games/ao-adventurer/drive_c/Funcom $AO_BASE/$dir/drive_c/"
    done
    echo ""
    echo "  2. Launch each individually first to configure windowed/borderless mode"
    echo "  3. Then run: ao-launch.sh"
}

get_ao_addresses() {
    hyprctl clients -j | jq -r '.[] | select(.class == "anarchyonline.exe") | .address' 2>/dev/null
}

find_new_window() {
    # Find an AO window address that we haven't claimed yet
    local addr
    for addr in $(get_ao_addresses); do
        local claimed=false
        for c in "${CLAIMED_ADDRS[@]}"; do
            [ "$addr" = "$c" ] && claimed=true && break
        done
        $claimed || { echo "$addr"; return 0; }
    done
    return 1
}

launch_instance() {
    local name="$1"
    local prefix="$2"
    local cores="$3"
    local size="$4"
    local pos="$5"
    local ws="$6"

    if [ ! -d "$prefix" ]; then
        echo "ERROR: Prefix not found: $prefix"
        echo "Run 'ao-launch.sh setup' first."
        return 1
    fi

    local ao_dir="$prefix/$AO_DIR"

    if [ ! -f "$ao_dir/AnarchyOnline.exe" ]; then
        echo "ERROR: AO not found at: $ao_dir/AnarchyOnline.exe"
        echo "Install AO into the prefix first."
        return 1
    fi

    echo "Launching: $name (cores $cores)"
    (cd "$ao_dir" && WINEPREFIX="$prefix" WINEDEBUG=-all AMD_DEBUG=nodma taskset -c "$cores" wine "./AnarchyOnline.exe") &

    # Wait for the new window to appear
    echo "  Waiting for window..."
    local attempts=0
    local addr=""
    while [ $attempts -lt 30 ]; do
        addr=$(find_new_window)
        [ -n "$addr" ] && break
        sleep 1
        attempts=$((attempts + 1))
    done

    if [ -n "$addr" ]; then
        CLAIMED_ADDRS+=("$addr")
        # Move to workspace, set size and position
        hyprctl --batch "dispatch movetoworkspacesilent $ws,address:$addr; dispatch resizewindowpixel exact $size,address:$addr; dispatch movewindowpixel exact $pos,address:$addr" > /dev/null
        echo "  Positioned: $name on workspace $ws [${size// /x}] at (${pos// /,})"
    else
        echo "  Warning: Could not find window for $name after ${attempts}s"
    fi
}

# Stop all instances
if [ "$1" = "stop" ]; then
    echo "Stopping all AO instances..."
    pkill -f "AnarchyOnline.exe" 2>/dev/null
    sleep 1
    wineserver -k 2>/dev/null
    echo "Done."
    exit 0
fi

# Setup
if [ "$1" = "setup" ]; then
    setup_prefixes
    exit 0
fi

# Launch specific instance
if [[ "$1" =~ ^[1-3]$ ]]; then
    idx=$(( $1 - 1 ))
    IFS=':' read -r name dir cores size pos ws <<< "${INSTANCES[$idx]}"
    launch_instance "$name" "$AO_BASE/$dir" "$cores" "$size" "$pos" "$ws"
    exit 0
fi

# Launch all three
echo "=== Anarchy Online Triple Launcher ==="
echo ""
for inst in "${INSTANCES[@]}"; do
    IFS=':' read -r name dir cores size pos ws <<< "$inst"
    launch_instance "$name" "$AO_BASE/$dir" "$cores" "$size" "$pos" "$ws"
done
echo ""
echo "All instances launched!"
echo "Use 'ao-launch.sh stop' to kill all instances."
