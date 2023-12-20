{ config, lib, pkgs, home-manager, vars, ...  }:

let
inherit (config.home-manager.users.${vars.user}.lib.formats.rasi) mkLiteral;
colors = import ../theme/colors.nix;
in
{
	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				rofi-wayland
			];

			file = with colors.scheme.default.hex; {

				".config/rofi/shared/colors.rasi" = with colors.scheme.default; {
					text = ''
						* {
    background:     rgb(${rgb.bg}, 95%);
    background-alt: rgb(43, 43, 57, 95%);
    foreground:     rgb(${rgb.fg});
    selected:       rgb(${rgb.active}, 95%);
    border:         rgb(${rgb.active});
    active:         rgb(${rgb.active}, 95%);
    urgent:         rgb(${rgb.highlight});
}

					'';
				};

				".config/rofi/shared/fonts.rasi" = {
				text = ''
					/* Text Font */
* {
    font: "JetBrains Mono SemiBold Nerd Font Complete Mono 12";
/* font: "MonoLisaSemiBold Nerd Font Semi-Bold 12"; */
}
				'';
				};

				".config/rofi/launcher.rasi" = {
					text = ''
/**
 * Copyright (C) 2020-2022 Aditya Shakya <adi1090x@gmail.com>
 **/

/*****----- Configuration -----*****/
configuration {
    terminal:                   "kitty";
	modi:                       "drun,filebrowser,run";
    show-icons:                 true;
    display-drun:               " Apps";
    display-run:                " Run";
    display-filebrowser:        " Files";
    display-window:             " Windows";
	drun-display-format:        "{name}";
	window-format:              "{w} · {c} · {t}";
    run-shell-command:          "{terminal} --hold {cmd}";
    click-to-exit:              true;
    sort:                       false;
    m:                          -1;
}

/*****----- Global Properties -----*****/
@import                          "shared/fonts.rasi"
@import                          "shared/colors.rasi"

* {
    border-colour:               var(border);
    handle-colour:               var(selected);
    background-colour:           var(background);
    foreground-colour:           var(foreground);
    alternate-background:        var(background-alt);
    normal-background:           var(background);
    normal-foreground:           var(foreground);
    urgent-background:           var(urgent);
    urgent-foreground:           var(background);
    active-background:           var(active);
    active-foreground:           var(background);
    selected-normal-background:  var(selected);
    selected-normal-foreground:  var(background);
    selected-urgent-background:  var(active);
    selected-urgent-foreground:  var(background);
    selected-active-background:  var(urgent);
    selected-active-foreground:  var(background);
    alternate-normal-background: var(background);
    alternate-normal-foreground: var(foreground);
    alternate-urgent-background: var(urgent);
    alternate-urgent-foreground: var(background);
    alternate-active-background: var(active);
    alternate-active-foreground: var(background);
}

/*****----- Main Window -----*****/
window {
    /* properties for window widget */
    transparency:                "real";
    location:                    center;
    anchor:                      center;
    fullscreen:                  false;
    width:                       30%;
    x-offset:                    0px;
    y-offset:                    0px;

    /* properties for all widgets */
    enabled:                     true;
    margin:                      0px;
    padding:                     0px;
    border:                      2px solid;
    border-radius:               5px;
    border-color:                @border-colour;
    cursor:                      "default";
    /* Backgroud Colors */
    background-color:            @background-colour;
    /* Backgroud Image */
    //background-image:          url("/path/to/image.png", none);
    /* Simple Linear Gradient */
    //background-image:          linear-gradient(red, orange, pink, purple);
    /* Directional Linear Gradient */
    //background-image:          linear-gradient(to bottom, pink, yellow, magenta);
    /* Angle Linear Gradient */
    //background-image:          linear-gradient(45, cyan, purple, indigo);
}

/*****----- Main Box -----*****/
mainbox {
    enabled:                     true;
    spacing:                     10px;
    margin:                      0px;
    padding:                     10px 20px;
    border:                      0px solid;
    border-radius:               0px 0px 0px 0px;
    border-color:                @border-colour;
    background-color:            transparent;
    children:                    [ "inputbar", "listview", "message", "mode-switcher" ];
}

/*****----- Inputbar -----*****/
inputbar {
    enabled:                     true;
    spacing:                     10px;
    margin:                      0px;
    padding:                     10px;
    border:                      0px solid;
    border-radius:               6px;
    border-color:                @border-colour;
    /* background-color:            @background-alt; */
    background-color:            transparent;
    text-color:                  @foreground-colour;
    children:                    [ "textbox-prompt-colon", "entry" ];
}

prompt {
    enabled:                     true;
    background-color:            inherit;
    text-color:                  inherit;
}
textbox-prompt-colon {
    enabled:                     true;
    expand:                      false;
    str:                         "❯ ";
    background-color:            inherit;
    text-color:                  inherit;
}
entry {
    enabled:                     true;
    background-color:            inherit;
    text-color:                  inherit;
    cursor:                      text;
    placeholder:                 "Search...";
    placeholder-color:           inherit;
}
num-filtered-rows {
    enabled:                     true;
    expand:                      false;
    background-color:            inherit;
    text-color:                  inherit;
}
textbox-num-sep {
    enabled:                     true;
    expand:                      false;
    str:                         "/";
    background-color:            inherit;
    text-color:                  inherit;
}
num-rows {
    enabled:                     true;
    expand:                      false;
    background-color:            inherit;
    text-color:                  inherit;
}
case-indicator {
    enabled:                     true;
    background-color:            inherit;
    text-color:                  inherit;
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     1;
    lines:                       10;
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false;
    layout:                      vertical;
    reverse:                     false;
    fixed-height:                true;
    fixed-columns:               true;
    
    spacing:                     5px;
    margin:                      0px;
    padding:                     0px;
    border:                      0px solid;
    border-radius:               0px;
    border-color:                @border-colour;
    background-color:            transparent;
    text-color:                  @foreground-colour;
    cursor:                      "default";
}
scrollbar {
    handle-width:                5px ;
    handle-color:                @handle-colour;
    border-radius:               10px;
    background-color:            @alternate-background;
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    spacing:                     10px;
    margin:                      0px;
    padding:                     2px;
    border:                      0px solid;
    border-radius:               0px;
    border-color:                @border-colour;
    background-color:            transparent;
    text-color:                  @foreground-colour;
    cursor:                      pointer;
}
element normal.normal {
    /* background-color:            var(normal-background); */
    background-color:            transparent;
    text-color:                  var(normal-foreground);
}
element normal.urgent {
    background-color:            var(urgent-background);
    background-color:            transparent;
    text-color:                  var(urgent-foreground);
}
element normal.active {
    background-color:            var(active-background);
    text-color:                  var(active-foreground);
}
element selected.normal {
    background-color:            var(selected);
    text-color:                  var(background);
}
element selected.urgent {
    background-color:            var(selected-urgent-background);
    text-color:                  var(selected-urgent-foreground);
}
element selected.active {
    background-color:            var(selected-active-background);
    text-color:                  var(selected-active-foreground);
}
element alternate.normal {
    /* background-color:            var(alternate-normal-background); */
    background-color:            transparent;
    text-color:                  var(alternate-normal-foreground);
}
element alternate.urgent {
    background-color:            var(alternate-urgent-background);
    text-color:                  var(alternate-urgent-foreground);
}
element alternate.active {
    background-color:            var(alternate-active-background);
    text-color:                  var(alternate-active-foreground);
}
element-icon {
    background-color:            transparent;
    text-color:                  inherit;
    size:                        40px;
    cursor:                      inherit;
}
element-text {
    background-color:            transparent;
    text-color:                  inherit;
    highlight:                   inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}

/*****----- Mode Switcher -----*****/
mode-switcher{
    enabled:                     true;
    expand:                      false;
    spacing:                     10px;
    margin:                      0px;
    padding:                     0px;
    border:                      0px solid;
    border-radius:               0px;
    border-color:                @border-colour;
    background-color:            transparent;
    text-color:                  @foreground-colour;
}
button {
    padding:                     10px;
    border:                      0px solid;
    border-radius:               6px;
    border-color:                @border-colour;
    /* background-color:            @alternate-background; */
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      pointer;
}
button selected {
    background-color:            var(active);
    text-color:                  var(background);
}

/*****----- Message -----*****/
message {
    enabled:                     true;
    margin:                      0px;
    padding:                     10px;
    border:                      0px solid;
    border-radius:               6px;
    border-color:                @border-colour;
    /* background-color:            @alternate-background; */
    background-color:            transparent;
    text-color:                  @foreground-colour;
}
textbox {
    border:                      0px solid;
    border-color:                @border-colour;
    background-color:            transparent;
    text-color:                  @foreground-colour;
    vertical-align:              0.5;
    horizontal-align:            0.0;
    highlight:                   none;
    placeholder-color:           @foreground-colour;
    blink:                       true;
    markup:                      true;
}
error-message {
    padding:                     20px;
    border:                      0px solid;
    border-radius:               6px;
    border-color:                @border-colour;
    background-color:            @background-colour;
    text-color:                  @foreground-colour;
}


						'';
				};

".config/rofi/powermenu.sh" = {
		text = ''
#!/usr/bin/env bash

RASI="$HOME/.config/rofi/powermenu.rasi"
CNFR="$HOME/.config/rofi/confirm.rasi"

# Theme Elements
prompt="`hostname` (`echo Stefandango/$USER`)"
mesg="Uptime : `uptime | sed -E 's/^[^,]*up *//; s/, *[[:digit:]]* users.*//; s/min/minutes/; s/([[:digit:]]+):0?([[:digit:]]+)/\1 hours, \2 minutes/'`"


# Options
layout=`cat ''${RASI} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$layout" == 'NO' ]]; then
	option_1=" Lock"
	option_2=" Logout"
	#option_3=" Suspend"
	option_3=" Reboot"
	option_4=" Shutdown"
else
	option_1=""
	option_2=""
	#option_3=""
	option_3=""
	option_4=""
fi
cnflayout=`cat ''${CNFR} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$cnflayout" == 'NO' ]]; then
	yes=' Yes'
	no=' No'
else
	yes=''
	no=''
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
		exec swaylock.sh
	elif [[ "$1" == '--opt2' ]]; then
		confirm_run "loginctl terminate-user $USER"
	elif [[ "$1" == '--opt3' ]]; then
		confirm_run 'loginctl reboot'
	elif [[ "$1" == '--opt4' ]]; then
		confirm_run 'loginctl poweroff'
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

'';
    executable = true;
		};

".config/rofi/powermenu.rasi" = {
	text = ''
/**
 * Copyright (C) 2020-2022 Aditya Shakya <adi1090x@gmail.com>
 **/

/*****----- Configuration -----*****/
configuration {
    show-icons:                 false;
}

/*****----- Global Properties -----*****/
@import                          "shared/colors.rasi"
@import                          "shared/fonts.rasi"

/*
USE_ICON=YES
*/

/*****----- Main Window -----*****/
window {
    transparency:                "real";
    location:                    center;
    anchor:                      center;
    fullscreen:                  false;
    width:                       800px;
    x-offset:                    0px;
    y-offset:                    0px;
    margin:                      0px;
    padding:                     0px;
    cursor:                      "default";
    background-color:            @background;
}

/*****----- Main Box -----*****/
mainbox {
    enabled:                     true;
    spacing:                     15px;
    margin:                      0px;
    padding:                     30px;
    background-color:            transparent;
    children:                    [ "inputbar", "message", "listview" ];
}

/*****----- Inputbar -----*****/
inputbar {
    enabled:                     true;
    spacing:                     10px;
    padding:                     0px;
    border:                      0px;
    border-radius:               0px;
    border-color:                @selected;
    background-color:            transparent;
    text-color:                  @foreground;
    children:                    [ "textbox-prompt-colon", "prompt"];
}

textbox-prompt-colon {
    enabled:                     true;
    expand:                      false;
    str:                         "";
    padding:                     10px 14px;
    border-radius:               0px;
    background-color:            @urgent;
    text-color:                  @background;
}
prompt {
    enabled:                     true;
    padding:                     10px;
    border-radius:               0px;
    background-color:            @active;
    text-color:                  @background;
}

/*****----- Message -----*****/
message {
    enabled:                     true;
    margin:                      0px;
    padding:                     10px;
    border:                      0px solid;
    border-radius:               0px;
    border-color:                @selected;
    background-color:            @background-alt;
    text-color:                  @foreground;
}
textbox {
    background-color:            inherit;
    text-color:                  inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     6;
    lines:                       1;
    cycle:                       true;
    scrollbar:                   false;
    layout:                      vertical;
    
    spacing:                     15px;
    background-color:            transparent;
    cursor:                      "default";
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    padding:                     30px 10px;
    border:                      0px solid;
    border-radius:               0px;
    border-color:                @selected;
    background-color:            transparent;
    text-color:                  @foreground;
    cursor:                      pointer;
}
element-text {
    font:                        "feather 28";
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.5;
}

element normal.normal,
element alternate.normal {
    background-color:            var(background-alt);
    text-color:                  var(foreground);
}
element normal.urgent,
element alternate.urgent,
element selected.active {
    background-color:            var(urgent);
    text-color:                  var(background);
}
element normal.active,
element alternate.active,
element selected.urgent {
    background-color:            var(active);
    text-color:                  var(background);
}
element selected.normal {
    background-color:            var(selected);
    text-color:                  var(background);
}


		'';
	};

		
			};	
		};

	};
}
