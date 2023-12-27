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

# Run the swww query command and create an associative array of monitor names and corresponding images
declare -A monitor_images
while read -r monitor; do
    # Generate a random image for each monitor initially
    monitor_images["$monitor"]=$(find "$1" -type f | shuf -n 1)
done < <(swww query | cut -d':' -f1)

while true; do
    for monitor in "${!monitor_images[@]}"; do
        img="${monitor_images[$monitor]}"
        
        # Set wallpaper for the current monitor
        swww img "$img" -o "$monitor" --transition-type random
	echo "$monitor $img"
        
        # Choose a new random image for the current monitor
        monitor_images["$monitor"]=$(find "$1" -type f | shuf -n 1)
    done
    
    sleep $INTERVAL
done
