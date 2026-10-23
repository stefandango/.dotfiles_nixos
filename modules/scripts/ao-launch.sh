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
#   ao-launch.sh launcher  # Start the PRK launcher (patching / DirectX layer)
#   ao-launch.sh launcher 2  # ...for instance 2's prefix
#
# Env:
#   AO_MANGOHUD=1          # overlay FPS/frametimes on the launched client(s)

. "$HOME/Scripts/hypr-compat.sh"

AO_BASE="$HOME/Games"
# Project Rubi-Ka installs the client here, not the old Funcom retail path.
# The PRK launcher (drive_c/PRK/PRK.Launcher.exe) owns patching; this script
# only launches the already-patched client.
AO_DIR="drive_c/PRK/client"

# Args the PRK launcher passes to the client. IA is the login server address as
# a little-endian uint32 (2642997703 -> 199.241.136.157), IP is the port, UI
# starts at the character screen. If PRK ever moves the server, the current
# values are logged on every launcher start in drive_c/PRK/logs/launcher*.txt
# as: "Ithaca - <ip>:<port> (IA <n> IP <n>)".
AO_ARGS=(IA 2642997703 IP 7000 UI)

# MangoHud FPS/frametime overlay, opt-in via AO_MANGOHUD=1. With the ao-vk
# renderer (randy31.dll in the client folder) it loads as an implicit Vulkan
# layer; on the stock renderer it hooks OpenGL via LD_PRELOAD for wine's
# built-in ddraw. Per-frame logging for stutter hunts:
#   MANGOHUD_CONFIG="read_cfg,output_folder=<dir>,autostart_log=1,log_interval=0"
MANGOHUD_WRAP=()
[ "${AO_MANGOHUD:-0}" = "1" ] && MANGOHUD_WRAP=(mangohud)

# Layout for 5120x2160 ultrawide:
#  Workspace 8: Adventurer fullscreen
#  Workspace 9: Fixer (left) + Bureaucrat (right) side by side
# No CPU pinning: it used to keep three clients off each other's cores, but the
# split was wrong (8-11 are the SMT siblings of 0-3) and a single client gains
# nothing from being held to 4 of 16 threads.
INSTANCES=(
    "Adventurer:ao-adventurer:5120 2160:0 0:8"
    "Fixer:ao-fixer:2560 2160:0 0:9"
    "Bureaucrat:ao-bureaucrat:2560 2160:2560 0:9"
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
    echo "  1. Install the client into the first prefix by running the PRK launcher:"
    echo "     WINEPREFIX=$AO_BASE/ao-adventurer wine \\"
    echo "       $AO_BASE/ao-adventurer/drive_c/PRK/PRK.Launcher.exe"
    echo "     (unzip win.zip from the PRK portal into drive_c/PRK first, then press"
    echo "      Play/Patch twice -- once self-updates the launcher, once fetches the client)"
    echo ""
    echo "  2. Clone that install into the other prefixes. -l hardlinks instead of"
    echo "     copying, which keeps ~3.2G per extra instance off the disk; the client"
    echo "     files are read-only in normal play, but re-run this after any patch"
    echo "     that rewrites them so the prefixes do not silently diverge:"
    for inst in "${INSTANCES[@]}"; do
        IFS=':' read -r _ dir _ _ _ <<< "$inst"
        [ "$dir" = "ao-adventurer" ] && continue
        echo "     cp -rl $AO_BASE/ao-adventurer/drive_c/PRK $AO_BASE/$dir/drive_c/"
    done
    echo ""
    echo "  3. Launch each individually first to configure windowed/borderless mode"
    echo "  4. Then run: ao-launch.sh"
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

# The client aborts with "Failed to set focus to the game window." because it
# does `if (SetFocus(hwnd) == NULL) throw` (0x403ea6) -- but SetFocus returns
# the *previous* focus window, which is NULL whenever nothing had focus yet.
# Since Wine 11.18 that is every start. Turn the jne at file offset 0x32B1 into
# a jmp so the check is skipped. Re-applied on every launch because a PRK
# client patch replaces the exe; the bytes around it are verified first so a
# different build is left alone. The first patch keeps AnarchyOnline.exe.orig.
# Cloned prefixes hardlink the exe, so patching one patches them all.
FOCUS_PATCH_OFFSET=$((0x32A6))
FOCUS_PATCH_ORIG="ff 15 98 b3 40 00 89 46 0c 85 c0 75 13 68 84 ba 40 00"
FOCUS_PATCH_DONE="ff 15 98 b3 40 00 89 46 0c 85 c0 eb 13 68 84 ba 40 00"

ensure_focus_patch() {
    local exe="$1/AnarchyOnline.exe"
    local bytes
    bytes=$(od -An -tx1 -j "$FOCUS_PATCH_OFFSET" -N 18 "$exe" | tr -d ' \n')

    case "$bytes" in
        "${FOCUS_PATCH_DONE// /}") return 0 ;;
        "${FOCUS_PATCH_ORIG// /}")
            [ -e "$exe.orig" ] || cp -p "$exe" "$exe.orig"
            printf '\xeb' | dd of="$exe" bs=1 seek=$((0x32B1)) conv=notrunc status=none
            echo "  Patched the focus check in $exe (original: $exe.orig)"
            ;;
        *)
            echo "  Warning: unknown AnarchyOnline.exe build, focus check not patched"
            echo "  (expect 'Failed to set focus to the game window.' on startup)"
            ;;
    esac
}

# PIDs of AnarchyOnline.exe clients running in the given prefix. Wine shows the
# client as "C:\PRK\client\AnarchyOnline.exe ...", so match that and check the
# prefix in its environment; the start.exe wrapper does not match.
client_pids() {
    local prefix="$1" pid
    for pid in $(pgrep -f '^C:.PRK.client.AnarchyOnline\.exe'); do
        tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
            | grep -qx "WINEPREFIX=$prefix" && echo "$pid"
    done
}

launch_instance() {
    local name="$1"
    local prefix="$2"
    local size="$3"
    local pos="$4"
    local ws="$5"

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

    local running
    running=$(client_pids "$prefix")
    if [ -n "$running" ]; then
        echo "ERROR: $name is already running in $prefix (pid ${running//$'\n'/ })"
        echo "A client that failed to start can sit hidden on its workspace using a"
        echo "full core. Stop it with 'ao-launch.sh stop', then launch again."
        return 1
    fi

    ensure_focus_patch "$ao_dir"

    echo "Launching: $name"
    (cd "$ao_dir" && WINEPREFIX="$prefix" WINEDEBUG=-all "${MANGOHUD_WRAP[@]}" wine "./AnarchyOnline.exe" "${AO_ARGS[@]}") &

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
        # Move to workspace, set size and position.
        # Via hypr_place_window: under the Lua config manager `hyprctl dispatch`
        # parses its argument as Lua, so the legacy `dispatch movetoworkspacesilent
        # 1,address:0x...` form is a syntax error and the windows never get placed.
        hypr_place_window "$addr" "$ws" "$size" "$pos"
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

# Start the PRK launcher instead of the game. Launching AnarchyOnline.exe
# directly (what everything below does) skips patching entirely, so run this
# after a PRK client update, and to reach settings the client itself does not
# expose -- notably DirectXLayer, which selects the bundled dgVoodoo2 builds.
# Keep it on aoia-resfix with ao-vk: "Default" drops dgVoodoo's DDraw.dll into
# the client folder, and ao-vk wants wine's own DirectDraw.
# Defaults to instance 1's prefix; each prefix patches independently.
if [ "$1" = "launcher" ]; then
    idx=$(( ${2:-1} - 1 ))
    if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#INSTANCES[@]}" ]; then
        echo "ERROR: instance must be 1-${#INSTANCES[@]}"
        exit 1
    fi
    IFS=':' read -r name dir _ _ _ <<< "${INSTANCES[$idx]}"
    prefix="$AO_BASE/$dir"
    launcher_dir="$prefix/drive_c/PRK"

    if [ ! -f "$launcher_dir/PRK.Launcher.exe" ]; then
        echo "ERROR: PRK launcher not found at: $launcher_dir/PRK.Launcher.exe"
        echo "Run 'ao-launch.sh setup' first."
        exit 1
    fi

    echo "Starting PRK launcher for $name ($prefix)"
    (cd "$launcher_dir" && WINEPREFIX="$prefix" WINEDEBUG=-all wine ./PRK.Launcher.exe)
    exit 0
fi

# Launch specific instance
if [[ "$1" =~ ^[1-3]$ ]]; then
    idx=$(( $1 - 1 ))
    IFS=':' read -r name dir size pos ws <<< "${INSTANCES[$idx]}"
    launch_instance "$name" "$AO_BASE/$dir" "$size" "$pos" "$ws"
    exit 0
fi

# Launch all three
echo "=== Anarchy Online Triple Launcher ==="
echo ""
for inst in "${INSTANCES[@]}"; do
    IFS=':' read -r name dir size pos ws <<< "$inst"
    launch_instance "$name" "$AO_BASE/$dir" "$size" "$pos" "$ws"
done
echo ""
echo "All instances launched!"
echo "Use 'ao-launch.sh stop' to kill all instances."
