#!/usr/bin/env bash

RASI="$HOME/.config/rofi/powermenu.rasi"
CNFR="$HOME/.config/rofi/confirm.rasi"

# Theme Elements
prompt="`hostname` (`echo Stefandango/$USER`)"
mesg="Uptime : `awk '{days=int($1/86400); hours=int(($1%86400)/3600); mins=int(($1%3600)/60); if(days>0) printf "%dd %dh %dm", days, hours, mins; else if(hours>0) printf "%dh %dm", hours, mins; else printf "%dm", mins}' /proc/uptime`"


# Options
layout=`cat ''${RASI} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$layout" == 'NO' ]]; then
	option_1="󰌾 Lock"
	option_2="󰗼 Logout"
	#option_3=" Suspend"
	option_3="󰑐 Reboot"
	option_4="󰐥 Shutdown"
else
	option_1="󰌾"
	option_2="󰗼"
	#option_3=""
	option_3="󰑐"
	option_4="󰐥"
fi
cnflayout=`cat ''${CNFR} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$cnflayout" == 'NO' ]]; then
	yes='󰸞 Yes'
	no=' No'
else
	yes='󰸞'
	no=''
fi

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$prompt" \
		-mesg "$mesg" \
		-markup-rows \
		-theme ''${RASI}
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd
}

# Confirmation CMD
confirm_cmd() {
	rofi -dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ''${CNFR}
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Confirm and execute
confirm_run () {	
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
        ''${1} && ''${2} && ''${3} && ''${4}
    else
        exit
    fi	
}

# Execute Command
run_cmd() {
	if [[ "$1" == '--opt1' ]]; then
		exec ~/Scripts/swaylock.sh
	elif [[ "$1" == '--opt2' ]]; then
		confirm_run "loginctl terminate-user $USER"
	elif [[ "$1" == '--opt3' ]]; then
		confirm_run 'systemctl reboot'
	elif [[ "$1" == '--opt4' ]]; then
		confirm_run 'systemctl poweroff'
	fi
}


# Actions
chosen="$(run_rofi)"
case ''${chosen} in
    $option_1)
		run_cmd --opt1
        ;;
    $option_2)
		run_cmd --opt2
        ;;
    $option_3)
		run_cmd --opt3
        ;;
    $option_4)
		run_cmd --opt4
        ;;
esac
