#!/bin/sh

# This script will randomly go through the files of a directory, setting it
# up as the wallpaper at regular intervals
#
# NOTE: this script is in bash (not posix shell), because the RANDOM variable
# we use is not defined in posix

if [[ $# -lt 1 ]] || [[ ! -d $1 ]]; then
    echo "Usage:
    $0 <dir containing images>"
    exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_STEP=2

# This controls (in seconds) when to switch to the next image
INTERVAL=300

# Function to find wallpapers with preference for time/season
find_wallpaper() {
    local base_dir="$1"
    
    # Try to find time/season specific wallpapers first
    local time_wallpaper=$(find "$base_dir" -type f \( -iname "*$TIME_PERIOD*" -o -iname "*$SEASON*" \) \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
    
    if [[ -n "$time_wallpaper" ]]; then
        echo "$time_wallpaper"
    else
        # Fallback to any wallpaper
        find "$base_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1
    fi
}

# Run the swww query command and create an associative array of monitor names and corresponding images
declare -A monitor_images
# Get current time info for dynamic wallpaper selection
HOUR=$(date +%H | sed 's/^0//')
MONTH=$(date +%m | sed 's/^0//')
DAY_OF_YEAR=$(date +%j)

# Determine time of day
if [[ $HOUR -ge 6 && $HOUR -lt 12 ]]; then
    TIME_PERIOD="morning"
elif [[ $HOUR -ge 12 && $HOUR -lt 17 ]]; then
    TIME_PERIOD="afternoon"
elif [[ $HOUR -ge 17 && $HOUR -lt 21 ]]; then
    TIME_PERIOD="evening"
else
    TIME_PERIOD="night"
fi

# Determine season
if [[ $MONTH -ge 3 && $MONTH -le 5 ]]; then
    SEASON="spring"
elif [[ $MONTH -ge 6 && $MONTH -le 8 ]]; then
    SEASON="summer"
elif [[ $MONTH -ge 9 && $MONTH -le 11 ]]; then
    SEASON="autumn"
else
    SEASON="winter"
fi

echo "Time: $TIME_PERIOD, Season: $SEASON"

while read -r monitor; do
    # Generate a random image for each monitor initially
    monitor_images["$monitor"]=$(find_wallpaper "$1")
done < <(swww query | cut -d':' -f1)

while true; do
    # Update time info each loop
    HOUR=$(date +%H | sed 's/^0//')
    MONTH=$(date +%m | sed 's/^0//')
    
    # Determine current time period
    if [[ $HOUR -ge 6 && $HOUR -lt 12 ]]; then
        TIME_PERIOD="morning"
    elif [[ $HOUR -ge 12 && $HOUR -lt 17 ]]; then
        TIME_PERIOD="afternoon"
    elif [[ $HOUR -ge 17 && $HOUR -lt 21 ]]; then
        TIME_PERIOD="evening"
    else
        TIME_PERIOD="night"
    fi
    
    # Determine current season
    if [[ $MONTH -ge 3 && $MONTH -le 5 ]]; then
        SEASON="spring"
    elif [[ $MONTH -ge 6 && $MONTH -le 8 ]]; then
        SEASON="summer"
    elif [[ $MONTH -ge 9 && $MONTH -le 11 ]]; then
        SEASON="autumn"
    else
        SEASON="winter"
    fi
    
    for monitor in "${!monitor_images[@]}"; do
        img="${monitor_images[$monitor]}"
        
        # Set wallpaper with appropriate transition
        if [[ $TIME_PERIOD == "morning" ]]; then
            transition="fade"
        elif [[ $TIME_PERIOD == "evening" ]]; then
            transition="wave"
        else
            transition="random"
        fi
        
        echo "$monitor $img ($TIME_PERIOD, $SEASON)"
        swww img "$img" -o "$monitor" --transition-type "$transition"
        
        # Choose a new wallpaper based on current time/season
        monitor_images["$monitor"]=$(find_wallpaper "$1")
    done
    
    sleep $INTERVAL
done
