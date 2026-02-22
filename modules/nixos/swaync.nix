{ config, lib, pkgs, vars, ... }:

let
colors = import ../../theme/colors.nix;
in
{
	home-manager.users.${vars.user} = {
		xdg.configFile = {
			"swaync/config.json".text = ''
			{
				"$schema": "/etc/xdg/swaync/configschema.json",

				"positionx": "right",
				"positiony": "top",
				"control-center-positionx": "none",
				"control-center-positiony": "none",
				"control-center-margin-top": 8,
				"control-center-margin-bottom": 8,
				"control-center-margin-right": 8,
				"control-center-margin-left": 8,
				"control-center-width": 500,
				"control-center-height": 1024,
				"fit-to-screen": false,

				"layer": "overlay",
				"control-center-layer": "overlay",
				"csspriority": "user",
				"notification-icon-size": 64,
				"notification-body-image-height": 100,
				"notification-body-image-width": 200,
				"notification-inline-replies": true,
				"timeout": 10,
				"timeout-low": 5,
				"timeout-critical": 0,
				"notification-window-width": 500,
				"keyboard-shortcuts": true,
				"image-visibility": "when-available",
				"transition-time": 200,
				"hide-on-clear": true,
				"hide-on-action": true,
				"script-fail-notify": true,
				"widgets": [
    "menubar#label",
/*					"title", */
				"volume",
				"mpris",
				"dnd",
				"notifications"
				],
				"widget-config": {
					"title": {
						"text": "Notification center",
						"clear-all-button": true,
						"button-text": "󰆴 clear all"
					},
					"dnd": {
						"text": "Do not disturb"
					},
					"label": {
						"max-lines": 1,
						"text": "Notification center"
					},
					"mpris": {
						"image-size": 96,
						"image-radius": 7
					},
					"volume": {
						"label": "󰕾"
					},
					"menubar#label": {
						"menu#power-buttons": {
							"label": "⏻", 
							"position": "right",
							"actions": [ 
							{
								"label": "\tReboot",
								"command": "systemctl reboot"
							},
							{
								"label": "\tLock",
								"command": "~/Scripts/swaylock.sh"
							},
							{
								"label": "\tLogout",
								"command": "${pkgs.hyprland}/bin/hyprctl dispatch exit"
							},
							{
								"label": "⏻\tShut down",
								"command": "systemctl poweroff"
							}
							]
						},
						"menu#powermode-buttons": {
							"label": "󰍜", 
							"position": "left",
							"actions": [ 
							{
								"label": "󰕾\tToggle sound",
								"command": "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"
							},
							{
								"label": "󰍬\tToggle mic",
								"command": "${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle"
							},
	{
								"label": "󰸉\tSwitch wallpaper",
								"command": "pkill swww_random.sh && ~/Scripts/swww_random.sh ~/Pictures/Wallpapers/ &"
							}

							]
						},
						"buttons#topbar-buttons": {
							"position": "left",
							"actions": [
							{
							
								"label": "󰹑",
								"command": "${pkgs.grimblast}/bin/grimblast --notify --freeze --wait 1 copysave area ~/Pictures/$(date +%Y-%m-%dT%H%M%S).png"
							}
							]
						}
					}

				}
			}			
			'';

			"swaync/style.default.css".text =  with colors.scheme.default; ''
			      @define-color cc-bg rgba(${rgb.bg}, 0.95);
          @define-color noti-border-color rgba(255, 255, 255, 0.15);
          @define-color noti-bg rgb(17, 17, 27);
          @define-color noti-bg-darker rgb(43, 43, 57);
          @define-color noti-bg-hover rgb(27, 27, 43);
          @define-color noti-bg-focus rgba(27, 27, 27, 0.6);
          @define-color noti-close-bg rgba(255, 255, 255, 0.1);
          @define-color noti-close-bg-hover rgba(255, 255, 255, 0.15);
          @define-color text-color rgba(${rgb.fg}, 1);
          @define-color text-color-disabled rgb(150, 150, 150);
          @define-color bg-selected rgb(${rgb.fg});
	  @define-color mpris-album-art-overlay rgba(0, 0, 0, 0.55);
	  @define-color mpris-button-hover rgba(0, 0, 0, 0.50);

          * {
            font-family: MonoLisa Nerd Font Semi-Bold;
            /*font-weight: bolder;*/
          }

          .control-center .notification-row:focus,
          .control-center .notification-row:hover {
            opacity: 1;
            background: @noti-bg-darker
          }

          .notification-row {
            outline: none;
            margin: 10px;
            padding: 0;
          }

          .notification {
            background: transparent;
            padding: 0;
            margin: 0px;
          }

          .notification-content {
            background: @cc-bg;
            padding: 10px;
            border-radius: 5px;
            border: 1px solid #${hex.active};
            margin: 0;
          }

          .notification-default-action {
            margin: 0;
            padding: 0;
            border-radius: 5px;
          }

          .close-button {
            background: #${hex.red};
            color: @cc-bg;
            text-shadow: none;
            padding: 0;
            border-radius: 5px;
            margin-top: 5px;
            margin-right: 5px;
          }

          .close-button:hover {
            box-shadow: none;
            background: #${hex.red};
            transition: all .15s ease-in-out;
            border: none;
          }

          .notification-action {
            border: 2px solid #${hex.active};
            border-top: none;
            border-radius: 5px;
          }

          .notification-default-action:hover,
          .notification-action:hover {
            color: #${hex.fg};
            background: #${hex.fg};
          }

          .notification-default-action {
            border-radius: 5px;
            margin: 0px;
          }

          .notification-default-action:not(:only-child) {
            border-bottom-left-radius: 7px;
            border-bottom-right-radius: 7px;
          }

          .notification-action:first-child {
            border-bottom-left-radius: 10px;
            background: #1b1b2b;
          }

          .notification-action:last-child {
            border-bottom-right-radius: 10px;
            background: #1b1b2b;
          }

          .inline-reply {
            margin-top: 8px;
          }

          .inline-reply-entry {
            background: @noti-bg-darker;
            color: @text-color;
            caret-color: @text-color;
            border: 1px solid @noti-border-color;
            border-radius: 5px;
          }

          .inline-reply-button {
            margin-left: 4px;
            background: @noti-bg;
            border: 1px solid @noti-border-color;
            border-radius: 5px;
            color: @text-color;
          }

          .inline-reply-button:disabled {
            background: initial;
            color: @text-color-disabled;
            border: 1px solid transparent;
          }

          .inline-reply-button:hover {
            background: @noti-bg-hover;
          }

          .body-image {
            margin-top: 6px;
            background-color: #fff;
            border-radius: 5px;
          }

          .summary {
            font-size: 10px;
            font-weight: 700;
            background: transparent;
            color: rgba(${rgb.fg}, 1);
            text-shadow: none;
          }

          .time {
            font-size: 10px;
            font-weight: 700;
            background: transparent;
            color: @text-color;
            text-shadow: none;
            margin-right: 18px;
          }

          .body {
            font-size: 12px;
            font-weight: 400;
            background: transparent;
            color: @text-color;
            text-shadow: none;
          }

          .control-center {
            background: @cc-bg;
            border: 2px solid #${hex.active};
            border-radius: 10px;
          }

          .control-center-list {
            background: transparent;
          }

          .control-center-list-placeholder {
            opacity: .5;
          }

          .floating-notifications {
            background: transparent;
          }

          .blank-window {
            background: alpha(black, 0.1);
          }

          .widget-title {
            color: #${hex.fg};
            /*background: @noti-bg-darker;*/
            padding: 0px 10px;
            margin: 10px 10px 5px 10px;
            font-size: 12px;
            border-radius: 5px;
          }

          .widget-title>button {
            font-size: 10px;
            color: @text-color;
            text-shadow: none;
            background: @noti-bg;
            box-shadow: none;
            border-radius: 5px;
          }

          .widget-title>button:hover {
            background: #${hex.red};
            color: @cc-bg;
          }

          .widget-dnd {
            background: @noti-bg-darker;
            padding: 5px 10px;
            margin: 10px 10px 5px 10px;
            border-radius: 10px;
            font-size: 12px;
            color: #${hex.fg};
          }

          .widget-dnd>switch {
            border-radius: 10px;
            background: #${hex.fg};
          }

          .widget-dnd>switch:checked {
            background: #${hex.red};
            border: 1px solid #${hex.red};
          }

          .widget-dnd>switch slider {
            background: @cc-bg;
            border-radius: 10px;
          }

          .widget-dnd>switch:checked slider {
            background: @cc-bg;
            border-radius: 10px;
          }

          .widget-label {
            margin: 10px 10px 5px 10px;
          }

          .widget-label>label {
            font-size: 1rem;
            color: @text-color;
          }

          .widget-mpris {
            color: @text-color;
            background: @noti-bg-darker;
            padding: 0px 0px;
            margin: 10px 10px 5px 10px;
            border-radius: 5px;
          }

          .widget-mpris > box > button {
            border-radius: 5px;
          }

          .widget-mpris-player {
            padding: 0px 0px;
            margin: 5px;
          }

          .widget-mpris-title {
            font-size: 12px;
          }

          .widget-mpris-subtitle {
            font-size: 10px;
          }

          .widget-buttons-grid {
            font-size: 14px;
            padding: 0px;
            margin: 10px 10px 5px 10px;
            border-radius: 5px;
            /*background: @noti-bg-darker;*/
          }

          .widget-buttons-grid>flowbox>flowboxchild>button {
            margin: 0px;
            background: @cc-bg;
            border-radius: 5px;
            color: @text-color;
          }

          .widget-buttons-grid>flowbox>flowboxchild>button:hover {
            background: rgba(${rgb.fg}, 1);
            color: @cc-bg;
          }

          .widget-menubar>box>.menu-button-bar>button {
            border: none;
            background: transparent;
          }

          .topbar-buttons>button {
            border: none;
            background: transparent;
          }

          .widget-volume {
            background: @noti-bg-darker;
            padding: 10px;
            margin: 10px 10px 5px 10px;
            border-radius: 5px;
            font-size: x-large;
            color: @text-color;
          }

          .widget-volume>box>button {
            background: #${hex.active};
            border: none;
          }

          .per-app-volume {
            background-color: @noti-bg;
            padding: 4px 8px 8px;
            margin: 0 8px 8px;
            border-radius: 5px;
          }

          .widget-backlight {
            background: @noti-bg-darker;
            padding: 5px;
            margin: 10px 10px 5px 10px;
            border-radius: 5px;
            font-size: x-large;
            color: @text-color;
          }

          trough {
            background: #${hex.fg};
          }

          highlight{
            background: #${hex.active};
          }
.power-buttons{
  /*background-color: @noti-bg;
  padding: 8px;
  margin: 8px;
  border-radius: 12px;*/
  font-size: 14px;
            padding: 0px;
            margin: 10px 10px 5px 10px;
            border-radius: 5px;

}


.power-buttons>button {
  background: transparent;
  border: none;
}

.power-buttons>button:hover {
  background: @noti-bg-hover;
}

.widget-menubar>box>.menu-button-bar>button{
  border: none;
  background: transparent;
}

.topbar-buttons>button{
  border: none;
  background: transparent;
}

.widget-buttons-grid{
  padding: 8px;
  margin: 8px;
  border-radius: 12px;
  background-color: @noti-bg;
}

.widget-buttons-grid>flowbox>flowboxchild>button{
  background: @noti-bg;
  border-radius: 12px;
}

.widget-buttons-grid>flowbox>flowboxchild>button:hover {
  background: @noti-bg-hover;
}

.powermode-buttons{
  background-color: @noti-bg;
  padding: 8px;
  margin: 8px;
  border-radius: 12px;
}

.powermode-buttons>button {
  background: transparent;
  border: none;
}

.powermode-buttons>button:hover {
  background: @noti-bg-hover;
}
'';	
		};
	};
}
