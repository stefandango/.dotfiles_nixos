#!/usr/bin/env bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nix-updates"
CACHE_FILE="$CACHE_DIR/updates.json"
DIFF_FILE="$CACHE_DIR/diff.txt"
LOCK_FILE="$CACHE_DIR/check.lock"
DIFF_LOCK="$CACHE_DIR/diff.lock"
FLAKE_DIR="$HOME/.dotfiles"
HOSTNAME="stefan"
MAX_AGE=$((4 * 3600)) # 4 hours

mkdir -p "$CACHE_DIR"

# Colors for terminal output
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
RESET='\033[0m'

check_updates() {
    if [ -f "$LOCK_FILE" ]; then
        return
    fi
    touch "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"' EXIT

    # Resolve the actual top-level nixpkgs node — `.nodes.nixpkgs` may be a
    # transitive dep (e.g. an input that doesn't `follows`); root.inputs.nixpkgs
    # is the authoritative pointer.
    nixpkgs_node=$(jq -r '.nodes.root.inputs.nixpkgs // "nixpkgs"' "$FLAKE_DIR/flake.lock" 2>/dev/null)
    current_rev=$(jq -r --arg n "$nixpkgs_node" '.nodes[$n].locked.rev' "$FLAKE_DIR/flake.lock" 2>/dev/null)
    if [ -z "$current_rev" ] || [ "$current_rev" = "null" ]; then
        return
    fi

    branch=$(jq -r --arg n "$nixpkgs_node" '.nodes[$n].original.ref // "nixos-unstable"' "$FLAKE_DIR/flake.lock" 2>/dev/null)

    latest_info=$(curl -sf -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/NixOS/nixpkgs/commits/$branch" 2>/dev/null)

    if [ -z "$latest_info" ]; then
        return
    fi

    latest_rev=$(echo "$latest_info" | jq -r '.sha')
    latest_date=$(echo "$latest_info" | jq -r '.commit.committer.date')

    current_epoch=$(jq -r --arg n "$nixpkgs_node" '.nodes[$n].locked.lastModified' "$FLAKE_DIR/flake.lock" 2>/dev/null)
    current_date_fmt=$(date -d "@$current_epoch" '+%Y-%m-%d' 2>/dev/null || echo "unknown")
    latest_date_fmt=$(date -d "$latest_date" '+%Y-%m-%d' 2>/dev/null || echo "$latest_date")

    if [ "$current_rev" = "$latest_rev" ]; then
        jq -n --arg current_date "$current_date_fmt" \
            '{status: "current", current_date: $current_date}' \
            > "$CACHE_FILE"
        rm -f "$DIFF_FILE"
    else
        latest_epoch=$(date -d "$latest_date" '+%s' 2>/dev/null)
        days_behind=$(( (latest_epoch - current_epoch) / 86400 ))

        jq -n \
            --arg current_date "$current_date_fmt" \
            --arg latest_date "$latest_date_fmt" \
            --argjson days "$days_behind" \
            --arg latest_rev "$latest_rev" \
            '{status: "outdated", current_date: $current_date, latest_date: $latest_date, days: $days, latest_rev: $latest_rev}' \
            > "$CACHE_FILE"
    fi
}

build_diff() {
    if [ -f "$DIFF_LOCK" ]; then
        return
    fi
    touch "$DIFF_LOCK"
    trap 'rm -f "$DIFF_LOCK"' EXIT

    nixpkgs_node=$(jq -r '.nodes.root.inputs.nixpkgs // "nixpkgs"' "$FLAKE_DIR/flake.lock" 2>/dev/null)
    branch=$(jq -r --arg n "$nixpkgs_node" '.nodes[$n].original.ref // "nixos-unstable"' "$FLAKE_DIR/flake.lock" 2>/dev/null)
    latest_rev=$(jq -r '.latest_rev // ""' "$CACHE_FILE" 2>/dev/null)

    dry_output=$(nix build "$FLAKE_DIR#nixosConfigurations.$HOSTNAME.config.system.build.toplevel" \
        --override-input nixpkgs "github:NixOS/nixpkgs/$branch" \
        -o /tmp/nix-updates-result --no-write-lock-file --dry-run 2>&1)

    if [ $? -eq 0 ] || echo "$dry_output" | grep -q 'will be built\|will be fetched'; then
        packages=$(echo "$dry_output" | grep '\.drv$' | \
            sed 's|.*/[a-z0-9]*-||; s|\.drv$||' | \
            grep -v '^\(system-\|etc\b\|user-\|unit-\|activate\b\|X-Restart\|system-path\|nixos-system-\)' | \
            sort -u)

        if [ -n "$packages" ]; then
            {
                echo "$latest_rev"
                echo "$packages"
            } > "$DIFF_FILE"
        else
            {
                echo "$latest_rev"
                echo "No package changes detected."
            } > "$DIFF_FILE"
        fi
    else
        {
            echo "$latest_rev"
            echo "Failed to evaluate updated system. Try 'nixup' manually."
        } > "$DIFF_FILE"
    fi

    pkill -RTMIN+8 waybar 2>/dev/null
}

display() {
    clear
    echo ""
    echo -e "  ${BOLD}${CYAN}  NixOS Update Status${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
    echo ""

    if [ ! -f "$CACHE_FILE" ]; then
        echo -e "  ${DIM}No update information available yet.${RESET}"
        echo ""
        return
    fi

    status=$(jq -r '.status' "$CACHE_FILE")

    if [ "$status" = "current" ]; then
        current_date=$(jq -r '.current_date' "$CACHE_FILE")
        echo -e "  ${GREEN}${BOLD}  System is up to date${RESET}"
        echo -e "  ${DIM}Locked: $current_date${RESET}"
        echo ""
        return
    fi

    days=$(jq -r '.days' "$CACHE_FILE")
    current_date=$(jq -r '.current_date' "$CACHE_FILE")
    latest_date=$(jq -r '.latest_date' "$CACHE_FILE")

    echo -e "  ${YELLOW}${BOLD}$days days behind nixpkgs${RESET}"
    echo ""
    echo -e "  ${DIM}Current lock:${RESET}  $current_date"
    echo -e "  ${DIM}Latest nixpkgs:${RESET} $latest_date"
    echo ""

    if [ -f "$DIFF_FILE" ]; then
        packages=$(tail -n +2 "$DIFF_FILE")
        pkg_count=$(echo "$packages" | wc -l)

        echo -e "  ${BOLD}${BLUE}$pkg_count package(s) would be updated:${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
        echo ""
        echo "$packages" | while read -r pkg; do
            echo -e "    ${CYAN}•${RESET} $pkg"
        done
    else
        echo -e "  ${DIM}Evaluating package diff...${RESET}"
        echo -e "  ${DIM}This may take about a minute.${RESET}"
        echo ""

        build_diff

        if [ -f "$DIFF_FILE" ]; then
            packages=$(tail -n +2 "$DIFF_FILE")
            pkg_count=$(echo "$packages" | wc -l)

            echo -e "  ${BOLD}${BLUE}$pkg_count package(s) would be updated:${RESET}"
            echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
            echo ""
            echo "$packages" | while read -r pkg; do
                echo -e "    ${CYAN}•${RESET} $pkg"
            done
        fi
    fi

    echo ""
    echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
    echo -e "  ${DIM}Run${RESET} ${BOLD}nixup${RESET} ${DIM}to update${RESET}"
    echo ""
}

# Handle actions
case "$1" in
    --check)
        check_updates
        exit 0
        ;;
    --diff)
        build_diff
        exit 0
        ;;
    --display)
        display
        exit 0
        ;;
esac

# Check if cache needs refresh
if [ -f "$CACHE_FILE" ]; then
    cache_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if [ "$cache_age" -gt "$MAX_AGE" ]; then
        bash "$0" --check &>/dev/null &
        disown
    fi
else
    bash "$0" --check &>/dev/null &
    disown
fi

# Output for waybar
if [ ! -f "$CACHE_FILE" ]; then
    printf '{"text": "...", "tooltip": "Checking for updates...", "class": "checking"}\n'
    exit 0
fi

status=$(jq -r '.status' "$CACHE_FILE")

if [ "$status" = "current" ]; then
    current_date=$(jq -r '.current_date' "$CACHE_FILE")
    printf '{"text": "", "tooltip": "Up to date (%s)", "class": "current"}\n' "$current_date"
else
    days=$(jq -r '.days' "$CACHE_FILE")
    current_date=$(jq -r '.current_date' "$CACHE_FILE")
    latest_date=$(jq -r '.latest_date' "$CACHE_FILE")

    cached_latest_rev=$(jq -r '.latest_rev // ""' "$CACHE_FILE")
    diff_rev=$(head -1 "$DIFF_FILE" 2>/dev/null)
    if [ -f "$DIFF_FILE" ] && [ "$diff_rev" = "$cached_latest_rev" ]; then
        pkg_count=$(( $(tail -n +2 "$DIFF_FILE" | wc -l) ))
        printf '{"text": "󰏔 %s", "tooltip": "%s package(s) to update (%s days behind)\\nLocked: %s → Latest: %s\\nClick for details", "class": "updates"}\n' \
            "$pkg_count" "$pkg_count" "$days" "$current_date" "$latest_date"
    else
        printf '{"text": "󰏔 %sd", "tooltip": "%s days behind nixpkgs\\nLocked: %s → Latest: %s\\nClick for details", "class": "updates"}\n' \
            "$days" "$days" "$current_date" "$latest_date"
    fi
fi
