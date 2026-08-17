{config, lib, system, pkgs, vars, host, ... }:

let
  colors = import ../../theme/colors.nix;
  # rofi leaves a stale pidfile at $XDG_RUNTIME_DIR/rofi.pid when killed via SIGTERM
  # (pkill), which then blocks every later launch with "Rofi already running" and the
  # menu dies instantly. Remove it before (re)launching so the toggle keybinds keep working.
  rofiKill = "rm -f /run/user/$(id -u)/rofi.pid; pkill rofi";

  # Hyprland 0.55 deprecated hyprlang (hyprland.conf) in favour of a Lua config,
  # with upstream promising only "1 - 2 releases starting from 0.55" of continued
  # support. We're on 0.56.x, so the config below exists in both dialects.
  #
  # Both files are always written. Hyprland picks hyprland.lua when it is present
  # and only falls back to hyprland.conf otherwise ("[cfg] Lua config not found,
  # using legacy config at ..."), so flipping this to false is a complete revert.
  # The format is chosen once at startup — switching needs a full Hyprland
  # restart, `hyprctl reload` will not do it.
  #
  # Note the .conf path also needs modules/scripts/hypr-compat.sh, since
  # `hyprctl keyword` and legacy `hyprctl dispatch` only work under hyprlang.
  useLua = true;
in
{

	environment = {
		variables = {
			XDG_CURRENT_DESKTOP="Hyprland";
			XDG_SESSION_TYPE="wayland";
			XDG_SESSION_DESKTOP="Hyprland";
		};

		sessionVariables = {
			QT_QPA_PLATFORM = "wayland";
			QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
			GDK_BACKEND = "wayland";
			QT_WAYLAND_FORCE_DPI="physical";
			MOZ_ENABLE_WAYLAND = "1";
			KITTY_ENABLE_WAYLAND="1";
			SDL_VIDEODRIVER="wayland";

		};

		systemPackages = with pkgs; [
			grimblast       	# Screenshot
			hypridle        	# Idle Daemon
			hyprlock                # Lock Screen
			wl-clipboard    	# Clipboard
			wlr-randr       	# Monitor Settings
			hyprland-autoname-workspaces
			networkmanagerapplet
			cliphist
			awww			# Wallpaper daemon
			insync			# Gdrive integration
			thunar			# File explorer GUI
			thunar-volman		# Auto manage removable drives etc..
			imv			# Simple image viewer

			# Should be moved to own files
			swaynotificationcenter #loaded in seperate nix file
			libnotify

			#Other
			font-manager
			#obsidian
			playerctl		# Media playback control
			brightnessctl		# Brightness control

		];

	};
	programs = {
		hyprland = {                            # Window Manager
			enable = true;
			withUWSM = true;
			#package = hyprland.packages.${pkgs.system}.hyprland;
			#nvidiaPatches = true;
			xwayland.enable = true;
		};
		hyprlock.enable = true;                 # Sets up PAM (security.pam.services.hyprlock)
	};
	systemd.sleep.settings.Sleep = {
		AllowSuspend = "no";
		AllowHibernation = "no";
		AllowSuspendThenHibernate = "no";
		AllowHybridSleep = "yes";
	};

	home-manager.users.${vars.user} =
	let
	execute =''
	exec-once=${pkgs.hypridle}/bin/hypridle
	'';
	in
	let
		hyprlockConf = with colors.scheme.default.hex; ''
		general {
			disable_loading_bar = true
			grace = 3
			hide_cursor = true
			no_fade_in = false
		}

		background {
			monitor =
			path = screenshot
			blur_passes = 3
			blur_size = 8
			noise = 0.0117
			contrast = 0.8916
			brightness = 0.4
			vibrancy = 0.1696
			vibrancy_darkness = 0.0
		}

		input-field {
			monitor =
			size = 280, 60
			outline_thickness = 3
			dots_size = 0.25
			dots_spacing = 0.3
			dots_center = true
			dots_rounding = -1
			outer_color = rgba(${blue}ee)
			inner_color = rgba(0, 0, 0, 0.6)
			font_color = rgb(${fg})
			fade_on_empty = true
			placeholder_text = <i>Password...</i>
			hide_input = false
			rounding = 8
			check_color = rgba(${green}ee)
			fail_color = rgba(${red}ee)
			fail_text = <i>$FAIL ($ATTEMPTS)</i>
			fail_transition = 300
			capslock_color = rgba(${yellow}ee)
			position = 0, -20
			halign = center
			valign = center
		}

		label {
			monitor =
			text = cmd[update:1000] echo "$(date +"%H:%M:%S")"
			color = rgba(${fg}ff)
			font_size = 96
			font_family = JetBrainsMono Nerd Font
			position = 0, 240
			halign = center
			valign = center
		}

		label {
			monitor =
			text = cmd[update:60000] echo "$(date +"%A, %B %d")"
			color = rgba(${fg}ff)
			font_size = 24
			font_family = JetBrainsMono Nerd Font
			position = 0, 140
			halign = center
			valign = center
		}

		label {
			monitor =
			text =   $USER
			color = rgba(${fg}ff)
			font_size = 18
			font_family = JetBrainsMono Nerd Font
			position = 0, -120
			halign = center
			valign = center
		}
		'';

		# dpms is driven through hypr-compat.sh rather than `hyprctl dispatch dpms on`:
		# under the Lua config manager the dispatch argument is parsed as Lua, so the
		# legacy form dies with "')' expected near 'on'" and the screen never wakes.
		# The shim picks `hl.dsp.dpms("on")` or the legacy string per running manager.
		hypridleConf = ''
		general {
			lock_cmd = pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock
			before_sleep_cmd = loginctl lock-session
			after_sleep_cmd = /home/${vars.user}/Scripts/hypr-compat.sh dpms on
			ignore_dbus_inhibit = false
		}

		listener {
			timeout = 600
			on-timeout = loginctl lock-session
		}

		listener {
			timeout = 660
			on-timeout = /home/${vars.user}/Scripts/hypr-compat.sh dpms off
			on-resume = /home/${vars.user}/Scripts/hypr-compat.sh dpms on
		}
		'';

		hyprlandConf = with colors.scheme.default.hex;
		''
		autogenerated = 0

		# LG 45" ultrawide (update desc: string from hyprctl monitors if needed)
		monitor=desc:LG Electronics,5120x2160@120,auto,1
		monitor=,preferred,auto,auto

		env = XCURSOR_SIZE,28
		env = XCURSOR_THEME,Bibata-Modern-Classic

		# For all categories, see https://wiki.hyprland.org/Configuring/Variables/
		input {
			kb_layout = dk
				kb_variant =
				kb_model =
				kb_options =
				kb_rules =

				follow_mouse = 1

				touchpad {
					natural_scroll = no
				}

			sensitivity = 0.0 # -1.0 - 1.0, 0 means no modification.
		}

		general {
		# See https://wiki.hyprland.org/Configuring/Variables/ for more

			gaps_in = 5
				gaps_out = 20
				border_size = 2
				col.active_border = rgba(${cyan}ee) rgba(${green}ee) 45deg
				col.inactive_border = rgba(${gray}aa)

				layout = dwindle

		# Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
				allow_tearing = false
		}

		group {
			col.border_active = rgba(${cyan}ee)
			col.border_inactive = rgba(${gray}aa)

			groupbar {
				enabled = true
				font_size = 14
				height = 30
				render_titles = true
				col.active = rgb(${blue})
				col.inactive = rgb(${gray})
				text_color = rgb(ffffff)
				rounding = 6
				gaps_in = 3
				gaps_out = 3
				middle_click_close = true # 0.55: middle-click a tab to close that window
			}
		}

		decoration {
		# See https://wiki.hyprland.org/Configuring/Variables/ for more

			rounding = 10
			dim_inactive = true
			dim_strength = 0.15

				blur {
					enabled = true
					size = 8
					passes = 2
					vibrancy = 0.1696
				}

				shadow {
					enabled = true
					range = 15
					render_power = 2
					color = rgba(1a1a1aee)
				}

		}

		render {
			new_render_scheduling = true
		}

		animations {
			enabled = yes

		# Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

				bezier = myBezier, 0.25, 1, 0.5, 1
				# Spring-like overshoot curves. True spring curves are Lua-config only (0.55);
				# these béziers overshoot past 1.0 to approximate the springy settle in hyprlang.
				bezier = springy, 0.34, 1.56, 0.64, 1
				bezier = overshot, 0.05, 0.9, 0.1, 1.05

				animation = windows, 1, 5, springy
				animation = windowsOut, 1, 7, default, popin 80%
				animation = border, 1, 10, default
				animation = borderangle, 1, 8, default
				animation = fade, 1, 7, default
				animation = workspaces, 1, 5, overshot
		}

		dwindle {
		# See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
			# pseudotile option removed in Hyprland 0.55 — pseudotiling is now per-window via the `pseudo` dispatcher (bound to mainMod + P below)
				preserve_split = yes # you probably want this
		}

		gestures {
		# See https://wiki.hyprland.org/Configuring/Variables/ for more
		}

		misc {
		# See https://wiki.hyprland.org/Configuring/Variables/ for more
			force_default_wallpaper = 0
			# vfr moved to debug: in Hyprland 0.55 (default is already true)
			# vrr=3 (FreeSync only for fullscreen game/video content) instead of
			# vrr=1 (always-on). vrr=1 kept VRR active on the static/low-fps desktop,
			# and this LG 45GX950A WOLED has gamma tuned for ~120Hz, so the panel's
			# real refresh dropping toward the 48Hz VRR floor on the desktop caused
			# OLED gamma flicker -> the "flickers after a game" symptom. vrr=3 turns
			# VRR OFF on the desktop (no flicker) while keeping FreeSync IN games.
			# vrr=3 only toggles for game/video (not every fullscreen window like the
			# old crashing vrr=2), and the mode is capped to 5120x2160@120 (was @165):
			# 120Hz gives the DSC link margin so the VRR re-train is reliable (avoids
			# the DP-2-disconnect SIGSEGV) AND matches the panel's gamma-tuned point.
			vrr = 3
			disable_hyprland_logo = true
			disable_splash_rendering = true
			mouse_move_enables_dpms = true
			key_press_enables_dpms = true
			background_color = 0x${bg}
			enable_swallow = true
			swallow_regex = ^(kitty)$
		}


		# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

		# See https://wiki.hyprland.org/Configuring/Keywords/ for more
		$mainMod = SUPER

		# Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
		bind = $mainMod, Return, exec, kitty
		bind = $mainMod, Q, submap, kill
		submap=kill
		bind =,Q,killactive
		bind =,Q,submap,reset
		bind =,Return,killactive
		bind =,Return,submap,reset
		bind =,escape,submap,reset
		bind =,catchall,submap,reset
		submap=reset
		bind = SUPERSHIFT, SPACE, togglefloating
		bind = $mainMod, D, exec, ${rofiKill} || rofi -show drun -theme ~/.config/rofi/launcher.rasi
		bind = $mainMod, P, pseudo # dwindle
		bind = $mainMod, J, layoutmsg, togglesplit # dwindle (0.54+: via layoutmsg)
		bind=SUPERSHIFT,R,exec,${pkgs.hyprland}/bin/hyprctl reload
		bind=SUPER,F,fullscreen
		bind=SUPER,L,exec,${pkgs.hyprlock}/bin/hyprlock
		bind=SUPER,N,exec,${pkgs.swaynotificationcenter}/bin/swaync-client -t
		bind = SUPERSHIFT, E,exec, ${rofiKill} || $HOME/.config/rofi/powermenu.sh
        	bind=,print,exec,${pkgs.grimblast}/bin/grimblast --notify --freeze --wait 1 copysave area ~/Pictures/$(date +%Y-%m-%dT%H%M%S).png
		bind=SUPER,Y,exec,${rofiKill} || cliphist list | rofi -dmenu -theme $HOME/.config/rofi/clipboard.rasi | cliphist decode | wl-copy
		bind=SUPER,T,exec,${rofiKill} || ~/Scripts/waybar-tmux-manager.sh
		bind=SUPER,code:49,exec,pypr toggle term
		bind=SUPER,Z,exec, pypr zoom
		bind=SUPER,E,exec,pypr toggle files
		bind=SUPER,I,exec,~/Scripts/imv_launcher.sh
		bind=SUPERSHIFT,T,exec,${rofiKill} || ~/Scripts/theme-rofi.sh
		bind=SUPERSHIFT,F,exec,~/Scripts/focus-mode-toggle.sh
		bind=SUPERSHIFT,plus,exec,${rofiKill} || ~/Scripts/cheatsheet.sh
		bind=SUPERALT,SPACE,exec,${rofiKill} || ~/Scripts/omarchy-menu.sh

        	binde=,XF86AudioLowerVolume,exec,${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%
        	binde=,XF86AudioRaiseVolume,exec,${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%
         	bind=,XF86AudioMute,exec,${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle

        	bind=,XF86AudioMicMute,exec,${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ 1

		# Media playback
		bind=,XF86AudioPlay,exec,${pkgs.playerctl}/bin/playerctl play-pause
		bind=,XF86AudioNext,exec,${pkgs.playerctl}/bin/playerctl next
		bind=,XF86AudioPrev,exec,${pkgs.playerctl}/bin/playerctl previous
		bind=,XF86AudioStop,exec,${pkgs.playerctl}/bin/playerctl stop

		# Brightness
		binde=,XF86MonBrightnessUp,exec,${pkgs.brightnessctl}/bin/brightnessctl set +5%
		binde=,XF86MonBrightnessDown,exec,${pkgs.brightnessctl}/bin/brightnessctl set 5%-

		# Scratchpads
		bind=SUPER,B,exec,pypr toggle systeminfo
		bind=SUPERSHIFT,B,exec,pypr toggle lazydocker
		bind=SUPER,A,exec,pypr toggle pavucontrol

		# Window management submap
		bind = SUPER,R,exec,hyprctl keyword general:col.active_border "rgba(${yellow}ee) rgba(${orange}ee) 45deg"
		bind = SUPER,R,submap,window
		submap=window

		# Ratio presets (auto-exit after selection)
		bind =,1,exec,hyprctl --batch "keyword general:col.active_border 'rgba(${cyan}ee) rgba(${green}ee) 45deg'; dispatch splitratio exact 0.667; dispatch submap reset"
		bind =,2,exec,hyprctl --batch "keyword general:col.active_border 'rgba(${cyan}ee) rgba(${green}ee) 45deg'; dispatch splitratio exact 0.8; dispatch submap reset"
		bind =,3,exec,hyprctl --batch "keyword general:col.active_border 'rgba(${cyan}ee) rgba(${green}ee) 45deg'; dispatch splitratio exact 1.0; dispatch submap reset"
		bind =,4,exec,hyprctl --batch "keyword general:col.active_border 'rgba(${cyan}ee) rgba(${green}ee) 45deg'; dispatch splitratio exact 1.25; dispatch submap reset"
		bind =,5,exec,hyprctl --batch "keyword general:col.active_border 'rgba(${cyan}ee) rgba(${green}ee) 45deg'; dispatch splitratio exact 1.5; dispatch submap reset"
		bind =,e,exec,hyprctl --batch "keyword general:col.active_border 'rgba(${cyan}ee) rgba(${green}ee) 45deg'; dispatch splitratio exact 1.0; dispatch submap reset"

		# Toggle split direction
		bind =,s,exec,hyprctl --batch "keyword general:col.active_border 'rgba(${cyan}ee) rgba(${green}ee) 45deg'; dispatch layoutmsg togglesplit; dispatch submap reset"

		# Rotate split tree (0.55 dwindle layoutmsg) — repeatable, stays in submap
		bind =,r,layoutmsg,rotatesplit

		# Coarse resize for ultrawide (stay in submap, repeatable)
		binde =,right,resizeactive,100 0
		binde =,left,resizeactive,-100 0
		binde =,up,resizeactive,0 -100
		binde =,down,resizeactive,0 100

		# Very coarse resize
		binde =SHIFT,right,resizeactive,400 0
		binde =SHIFT,left,resizeactive,-400 0
		binde =SHIFT,up,resizeactive,0 -400
		binde =SHIFT,down,resizeactive,0 400

		# Exit
		bind =,escape,exec,hyprctl keyword general:col.active_border "rgba(${cyan}ee) rgba(${green}ee) 45deg"
		bind =,escape,submap,reset
		bind =SUPER,R,exec,hyprctl keyword general:col.active_border "rgba(${cyan}ee) rgba(${green}ee) 45deg"
		bind =SUPER,R,submap,reset
		submap=reset

		# Center floating window
		bind=SUPER,C,centerwindow

		# Pin floating window to all workspaces
		bind=SUPERSHIFT,P,pin

		# Move windows between monitors
		bind=SUPERALT,left,focusmonitor,-1
		bind=SUPERALT,right,focusmonitor,+1
		bind=SUPERALTSHIFT,left,movewindow,mon:-1
		bind=SUPERALTSHIFT,right,movewindow,mon:+1

		# Alt-tab window cycling
		bind=ALT,Tab,cyclenext
		bind=ALTSHIFT,Tab,cyclenext,prev

		# Window grouping (tabs)
		bind=SUPER,G,togglegroup
		bind=SUPERSHIFT,G,lockactivegroup,toggle
		bind=SUPER,Tab,changegroupactive,f
		bind=SUPERSHIFT,Tab,changegroupactive,b

		# Move focus with mainMod + arrow keys
		bind = $mainMod, left, movefocus, l
		bind = $mainMod, right, movefocus, r
		bind = $mainMod, up, movefocus, u
		bind = $mainMod, down, movefocus, d

		# Move active window + arrowkeys
		bind = SUPERSHIFT,left,movewindow, l
		bind = SUPERSHIFT,right,movewindow, r
		bind = SUPERSHIFT,up,movewindow, u
		bind = SUPERSHIFT,down,movewindow, d

		# Switch workspaces with mainMod + [0-9]
		bind = $mainMod, 1, workspace, 1
		bind = $mainMod, 2, workspace, 2
		bind = $mainMod, 3, workspace, 3
		bind = $mainMod, 4, workspace, 4
		bind = $mainMod, 5, workspace, 5
		bind = $mainMod, 6, workspace, 6
		bind = $mainMod, 7, workspace, 7
		bind = $mainMod, 8, workspace, 8
		bind = $mainMod, 9, workspace, 9
		bind = $mainMod, 0, workspace, 10

		# Move active window to a workspace with mainMod + SHIFT + [0-9]
		bind = $mainMod SHIFT, 1, movetoworkspace, 1
		bind = $mainMod SHIFT, 2, movetoworkspace, 2
		bind = $mainMod SHIFT, 3, movetoworkspace, 3
		bind = $mainMod SHIFT, 4, movetoworkspace, 4
		bind = $mainMod SHIFT, 5, movetoworkspace, 5
		bind = $mainMod SHIFT, 6, movetoworkspace, 6
		bind = $mainMod SHIFT, 7, movetoworkspace, 7
		bind = $mainMod SHIFT, 8, movetoworkspace, 8
		bind = $mainMod SHIFT, 9, movetoworkspace, 9
		bind = $mainMod SHIFT, 0, movetoworkspace, 10

		# Example special workspace (scratchpad)
		bind = $mainMod, S, togglespecialworkspace, magic
		bind = $mainMod SHIFT, S, movetoworkspace, special:magic

		# Scroll through existing workspaces with mainMod + scroll
		bind = $mainMod, mouse_down, workspace, e+1
		bind = $mainMod, mouse_up, workspace, e-1

		# Move/resize windows with mainMod + LMB/RMB and dragging
		bindm = $mainMod, mouse:272, movewindow
		bindm = $mainMod, mouse:273, resizewindow


		# Float common dialogs and popups
		windowrule = float on, match:title ^(Open File)(.*)$
		windowrule = float on, match:title ^(Open Folder)(.*)$
		windowrule = float on, match:title ^(Select a File)(.*)$
		windowrule = float on, match:title ^(Save As)(.*)$
		windowrule = float on, match:title ^(Save File)(.*)$
		windowrule = float on, match:title ^(File Upload)(.*)$
		windowrule = float on, match:title ^(Confirm)(.*)$
		windowrule = float on, match:title ^(Authentication)(.*)$
		windowrule = float on, match:title ^(Preferences)$
		windowrule = float on, match:title ^(Properties)$
		windowrule = float on, match:title ^(About )(.*)$
		windowrule = float on, match:title ^(Print)(.*)$
		windowrule = float on, match:title ^(Color Picker)(.*)$
		windowrule = float on, match:title ^(Sign in)(.*)$
		windowrule = float on, match:title ^(Settings)(.*)$
		windowrule = float on, match:title ^(Options)(.*)$
		windowrule = float on, match:title ^(Warning)(.*)$
		windowrule = float on, match:title ^(Error)(.*)$
		windowrule = float on, match:title ^(Progress)(.*)$
		windowrule = float on, match:title ^(Export)(.*)$
		windowrule = float on, match:title ^(Import)(.*)$
		windowrule = float on, match:title ^(Update)(.*)$
		windowrule = float on, match:title ^(Download)(.*)$

		# Float common popup app classes
		windowrule = float on, match:class ^(xdg-desktop-portal)(.*)$
		windowrule = float on, match:class ^(polkit)(.*)$
		windowrule = float on, match:class ^(zenity)(.*)$
		windowrule = float on, match:class ^(nm-connection-editor)$
		windowrule = float on, match:class ^(blueman)(.*)$
		windowrule = float on, match:class ^(font-manager)$

		# Steam client
		windowrule = float on, match:title ^(Steam)$
		windowrule = float on, match:title ^(Friends List)$

		# Steam games → workspace 10 fullscreen
		windowrule {
			name = steam-game
			match:class = ^(steam_app_.*)$
			workspace = 10
			fullscreen = on
		}

		# ...but NOT their launcher/splash windows. Those carry the same
		# steam_app_* class, so the rule above would blow a 600x400 splash up to
		# the full 5120x2160. Later rules win in Hyprland, so this one takes the
		# fullscreen back off and floats them at their natural size.
		# Regex is RE2: (?i) works, negative lookahead does NOT — so this is a
		# positive list. Add whatever your games actually call their loader
		# (find the exact title with the socket2 watcher, see note below).
		windowrule {
			name = steam-game-launcher
			match:class = ^(steam_app_.*)$
			match:title = (?i)^.*(launcher|launch|splash|loader|updater|patcher|setup|installer|configuration|config tool|settings|options|crash).*$
			fullscreen = off
			float = on
			center = on
		}

		# Anarchy Online multiboxing
		# Positioning handled by ao-launch.sh via hyprctl
		windowrule {
			name = ao-client
			match:class = ^(anarchyonline\.exe)$
			float = on
			opacity = 1.0 0.85
		}

		# Insync
		windowrule = float on, match:title ^(Insync)(.*)$

		# Scratchpad
		windowrule {
			name = scratchpad
			match:class = ^(scratchpad)$
			float = on
			center = on
			workspace = special silent
		}

		# Pavucontrol
		windowrule {
			name = pavucontrol
			match:class = ^(org\.pulseaudio\.pavucontrol|pavucontrol)$
			float = on
			size = 50% 40%
			center = on
			opacity = 0.80
		}

		# Thunar
		windowrule {
			name = thunar
			match:class = ^(thunar)$
			float = on
			opacity = 0.90
		}

		# Imv
		windowrule {
			name = imv
			match:class = ^(imv)$
			float = on
			size = 70% 70%
			center = on
		}

		# Layer rules for blur
		layerrule {
			name = blur-layers
			match:namespace = ^(rofi|waybar|swaync)$
			blur = on
			ignore_alpha = 0.5
		}

		# Opacity for certain apps
		windowrule = opacity 0.9 0.9, match:class ^(Slack|WebCord|Spotify|Kitty)$

		# Initialize theme files from Nix defaults before apps start
		exec-once = [ ! -f $HOME/.config/waybar/style.css ] && cp $HOME/.config/waybar/style.default.css $HOME/.config/waybar/style.css && chmod u+w $HOME/.config/waybar/style.css; [ ! -f $HOME/.config/rofi/shared/colors.rasi ] && cp $HOME/.config/rofi/shared/colors.default.rasi $HOME/.config/rofi/shared/colors.rasi && chmod u+w $HOME/.config/rofi/shared/colors.rasi; [ ! -f $HOME/.config/swaync/style.css ] && cp $HOME/.config/swaync/style.default.css $HOME/.config/swaync/style.css && chmod u+w $HOME/.config/swaync/style.css; true

		exec-once=${pkgs.awww}/bin/awww-daemon
		exec-once=${pkgs.waybar}/bin/waybar
		exec-once=${pkgs.openrazer-daemon}/bin/openrazer-daemon
		exec-once=${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
		# Start CoreCtrl minimized so its saved GPU profile (undervolt / power
		# limit) is applied at login. The real fix for this is the polkit rule in
		# hosts/nixos-desktop/default.nix that lets CoreCtrl start its root helper
		# without an auth prompt — without it CoreCtrl exited at boot with
		# "Cannot start helper". --minimize-systray asks it to start with no
		# window (minimized to the system tray), so it also needs a settled tray:
		# the theme-switcher (run at boot) does `pkill waybar; waybar`, so we wait
		# until Waybar's org.kde.StatusNotifierWatcher has been present
		# continuously for ~5s (the pkill resets the counter) before launching.
		#
		# QT_QPA_PLATFORMTHEME/QT_STYLE_OVERRIDE are unset for corectrl only: with
		# the system-wide qt.platformTheme = "gnome" (qgnomeplatform), Qt reports
		# "no system tray available", so --minimize-systray can't minimize and
		# corectrl pops its WINDOW at login instead of starting silently. corectrl
		# ignores QT_STYLE_OVERRIDE and forces its own style anyway, so dropping
		# both for this one process costs nothing and restores the silent launch.
		# (corectrl never registers a visible SNI tray icon here regardless — a
		# corectrl quirk on wlroots; Steam/insync/nm-applet tray icons work fine.)
		exec-once=bash -c 'unset QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE; stable=0; for i in $(seq 1 240); do if busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1; then stable=$((stable+1)); else stable=0; fi; [ "$stable" -ge 10 ] && break; sleep 0.5; done; exec ${pkgs.corectrl}/bin/corectrl --minimize-systray'
		exec-once=${pkgs.hyprland-autoname-workspaces}/bin/hyprland-autoname-workspaces
		exec-once=pypr
		exec-once = wl-clipboard-history -t
		exec-once = wl-paste --watch cliphist store
		exec-once = rm "$HOME/.cache/cliphist/db"   #it'll delete history at every restart
		exec-once = sleep 3 && ~/Scripts/awww_random.sh
		exec-once = sleep 4 && insync start --qt-qpa-platform=xcb --no-daemon
		# Restore saved theme if one was selected
		exec-once = sleep 2 && test -f $HOME/.config/theme/current && ~/Scripts/theme-switcher.sh $HOME/.config/theme/themes/$(cat $HOME/.config/theme/current).json
		${execute}
		'';

		# Lua port of hyprlandConf above (Hyprland 0.55+ config format).
		# Behaviourally 1:1 with the hyprlang version; see `useLua` at the top of
		# this file for how the two coexist. Validate changes without restarting:
		#   Hyprland --verify-config -c <file> 2>&1 | grep -q '^config ok$'
		# (the exit code is always 1, so the "config ok" line is the only signal;
		# it does catch unknown config keys and unknown rule fields, with line
		# numbers, but not wrong values inside layoutmsg strings.)
		hyprlandLua = with colors.scheme.default.hex;
		''
		------------------
		---- MONITORS ----
		------------------

		-- LG 45" ultrawide (update desc: string from hyprctl monitors if needed)
		hl.monitor({ output = "desc:LG Electronics", mode = "5120x2160@120", position = "auto", scale = 1 })
		hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

		-------------------------------
		---- ENVIRONMENT VARIABLES ----
		-------------------------------

		hl.env("XCURSOR_SIZE", "28")
		hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")

		-----------------------
		---- LOOK AND FEEL ----
		-----------------------

		-- Border gradients live in locals so the `window` submap can flip them at
		-- runtime via setBorder() below, in-process. The hyprlang config shelled out
		-- to `hyprctl keyword general:col.active_border ...` for this, which does not
		-- work under the Lua manager ("keyword can't work with non-legacy parsers").
		local BORDER_NORMAL   = { colors = { "rgba(${cyan}ee)", "rgba(${green}ee)" }, angle = 45 }
		local BORDER_WINDOW   = { colors = { "rgba(${yellow}ee)", "rgba(${orange}ee)" }, angle = 45 }
		local BORDER_INACTIVE = "rgba(${gray}aa)"

		local function setBorder(gradient)
			hl.config({ general = { col = { active_border = gradient } } })
		end

		hl.config({
			input = {
				kb_layout  = "dk",
				kb_variant = "",
				kb_model   = "",
				kb_options = "",
				kb_rules   = "",

				follow_mouse = 1,

				touchpad = {
					natural_scroll = false,
				},

				sensitivity = 0.0, -- -1.0 - 1.0, 0 means no modification.
			},

			general = {
				gaps_in     = 5,
				gaps_out    = 20,
				border_size = 2,

				col = {
					active_border   = BORDER_NORMAL,
					inactive_border = BORDER_INACTIVE,
				},

				layout = "dwindle",

				-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
				allow_tearing = false,
			},

			group = {
				col = {
					border_active   = "rgba(${cyan}ee)",
					border_inactive = "rgba(${gray}aa)",
				},

				groupbar = {
					enabled       = true,
					font_size     = 14,
					height        = 30,
					render_titles = true,
					col = {
						active   = "rgb(${blue})",
						inactive = "rgb(${gray})",
					},
					text_color         = "rgb(ffffff)",
					rounding           = 6,
					gaps_in            = 3,
					gaps_out           = 3,
					middle_click_close = true, -- 0.55: middle-click a tab to close that window
				},
			},

			decoration = {
				rounding     = 10,
				dim_inactive = true,
				dim_strength = 0.15,

				blur = {
					enabled  = true,
					size     = 8,
					passes   = 2,
					vibrancy = 0.1696,
				},

				shadow = {
					enabled      = true,
					range        = 15,
					render_power = 2,
					color        = "rgba(1a1a1aee)",
				},
			},

			render = {
				new_render_scheduling = true,
			},

			animations = {
				enabled = true,
			},

			dwindle = {
				-- pseudotile option removed in Hyprland 0.55 — pseudotiling is now per-window via the `pseudo` dispatcher (bound to mainMod + P below)
				preserve_split = true, -- you probably want this
			},

			misc = {
				force_default_wallpaper = 0,
				-- vfr moved to debug: in Hyprland 0.55 (default is already true)
				-- vrr=3 (FreeSync only for fullscreen game/video content) instead of
				-- vrr=1 (always-on). vrr=1 kept VRR active on the static/low-fps desktop,
				-- and this LG 45GX950A WOLED has gamma tuned for ~120Hz, so the panel's
				-- real refresh dropping toward the 48Hz VRR floor on the desktop caused
				-- OLED gamma flicker -> the "flickers after a game" symptom. vrr=3 turns
				-- VRR OFF on the desktop (no flicker) while keeping FreeSync IN games.
				-- vrr=3 only toggles for game/video (not every fullscreen window like the
				-- old crashing vrr=2), and the mode is capped to 5120x2160@120 (was @165):
				-- 120Hz gives the DSC link margin so the VRR re-train is reliable (avoids
				-- the DP-2-disconnect SIGSEGV) AND matches the panel's gamma-tuned point.
				vrr                      = 3,
				disable_hyprland_logo    = true,
				disable_splash_rendering = true,
				mouse_move_enables_dpms  = true,
				key_press_enables_dpms   = true,
				background_color         = 0x${bg},
				enable_swallow           = true,
				swallow_regex            = "^(kitty)$",
			},
		})

		-- Spring-like overshoot curves, kept as béziers for a 1:1 port. Real spring
		-- curves (hl.curve(name, { type = "spring", mass, stiffness, dampening })) are
		-- Lua-only and are the obvious follow-up now that the format allows them.
		hl.curve("myBezier", { type = "bezier", points = { { 0.25, 1 },    { 0.5, 1 }    } })
		hl.curve("springy",  { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 }   } })
		hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 },  { 0.1, 1.05 } } })

		hl.animation({ leaf = "windows",     enabled = true, speed = 5,  bezier = "springy" })
		hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default",  style = "popin 80%" })
		hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
		hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
		hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
		hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,  bezier = "overshot" })

		---------------------
		---- KEYBINDINGS ----
		---------------------

		local mainMod  = "SUPER"
		local rofiKill = [[${rofiKill}]]

		hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))

		-- Kill submap: SUPER+Q arms it, then Q or Return confirms.
		hl.bind(mainMod .. " + Q", hl.dsp.submap("kill"))
		hl.define_submap("kill", function()
			-- hyprlang stacked two binds on one key (killactive, then submap reset);
			-- in Lua a single function does both, with unambiguous ordering.
			local function killAndReset()
				hl.dispatch(hl.dsp.window.close())
				hl.dispatch(hl.dsp.submap("reset"))
			end
			hl.bind("Q",        killAndReset)
			hl.bind("Return",   killAndReset)
			hl.bind("escape",   hl.dsp.submap("reset"))
			hl.bind("catchall", hl.dsp.submap("reset"))
		end)

		hl.bind("SUPER + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
		hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(rofiKill .. [[ || rofi -show drun -theme ~/.config/rofi/launcher.rasi]]))
		hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())       -- dwindle
		hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle (0.54+: via layoutmsg)
		hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("${pkgs.hyprland}/bin/hyprctl reload"))
		hl.bind("SUPER + F", hl.dsp.window.fullscreen())
		hl.bind("SUPER + L", hl.dsp.exec_cmd("${pkgs.hyprlock}/bin/hyprlock"))
		hl.bind("SUPER + N", hl.dsp.exec_cmd("${pkgs.swaynotificationcenter}/bin/swaync-client -t"))
		hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(rofiKill .. [[ || $HOME/.config/rofi/powermenu.sh]]))
		hl.bind("print", hl.dsp.exec_cmd([[${pkgs.grimblast}/bin/grimblast --notify --freeze --wait 1 copysave area ~/Pictures/$(date +%Y-%m-%dT%H%M%S).png]]))
		hl.bind("SUPER + Y", hl.dsp.exec_cmd(rofiKill .. [[ || cliphist list | rofi -dmenu -theme $HOME/.config/rofi/clipboard.rasi | cliphist decode | wl-copy]]))
		hl.bind("SUPER + T", hl.dsp.exec_cmd(rofiKill .. [[ || ~/Scripts/waybar-tmux-manager.sh]]))
		-- Was `code:49` under hyprlang. The Lua bind parser silently swallows
		-- `code:NN` (0.56.1 registers the bind with an empty key and keycode 0, so it
		-- never fires), so this uses the keysym. Keycode 49 is <TLDE>, which on the
		-- dk layout set above is `onehalf` (½) — layout-dependent, unlike code:.
		hl.bind("SUPER + onehalf", hl.dsp.exec_cmd("pypr toggle term"))
		hl.bind("SUPER + Z", hl.dsp.exec_cmd("pypr zoom"))
		hl.bind("SUPER + E", hl.dsp.exec_cmd("pypr toggle files"))
		hl.bind("SUPER + I", hl.dsp.exec_cmd("~/Scripts/imv_launcher.sh"))
		hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(rofiKill .. [[ || ~/Scripts/theme-rofi.sh]]))
		hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("~/Scripts/focus-mode-toggle.sh"))
		hl.bind("SUPER + SHIFT + plus", hl.dsp.exec_cmd(rofiKill .. [[ || ~/Scripts/cheatsheet.sh]]))
		hl.bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd(rofiKill .. [[ || ~/Scripts/omarchy-menu.sh]]))

		-- Volume
		hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"), { repeating = true })
		hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"), { repeating = true })
		hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"))
		hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ 1"))

		-- Media playback
		hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl play-pause"))
		hl.bind("XF86AudioNext", hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl next"))
		hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl previous"))
		hl.bind("XF86AudioStop", hl.dsp.exec_cmd("${pkgs.playerctl}/bin/playerctl stop"))

		-- Brightness
		hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl set +5%"), { repeating = true })
		hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl set 5%-"), { repeating = true })

		-- Scratchpads
		hl.bind("SUPER + B",         hl.dsp.exec_cmd("pypr toggle systeminfo"))
		hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("pypr toggle lazydocker"))
		hl.bind("SUPER + A",         hl.dsp.exec_cmd("pypr toggle pavucontrol"))

		-- Window management submap.
		-- The hyprlang version ran `hyprctl --batch "keyword ...; dispatch ..."` for
		-- every entry; `hyprctl keyword` is dead under Lua, so these are now plain
		-- Lua callbacks doing the same work in-process (no subshell, no hyprctl).
		hl.bind("SUPER + R", function()
			setBorder(BORDER_WINDOW)
			hl.dispatch(hl.dsp.submap("window"))
		end)

		-- Dwindle's split ratio is clamped to [0.1, 1.9].
		local RATIO_MIN = 0.1

		hl.define_submap("window", function()
			-- Ratio presets (auto-exit after selection).
			-- The Lua layout dispatcher takes a *delta* only — "splitratio exact 0.667"
			-- is rejected with `failed to parse "exact" as a delta`, so hyprlang's
			-- `dispatch splitratio exact X` has no direct equivalent. Driving the ratio
			-- into the clamp floor first and then adding (X - 0.1) lands on exactly X.
			local function ratio(target)
				return function()
					setBorder(BORDER_NORMAL)
					hl.dispatch(hl.dsp.layout("splitratio -10"))
					hl.dispatch(hl.dsp.layout("splitratio " .. string.format("%.4f", target - RATIO_MIN)))
					hl.dispatch(hl.dsp.submap("reset"))
				end
			end
			hl.bind("1", ratio(0.667))
			hl.bind("2", ratio(0.8))
			hl.bind("3", ratio(1.0))
			hl.bind("4", ratio(1.25))
			hl.bind("5", ratio(1.5))
			hl.bind("e", ratio(1.0))

			-- Toggle split direction
			hl.bind("s", function()
				setBorder(BORDER_NORMAL)
				hl.dispatch(hl.dsp.layout("togglesplit"))
				hl.dispatch(hl.dsp.submap("reset"))
			end)

			-- Rotate split tree (0.55 dwindle layoutmsg) — repeatable, stays in submap
			hl.bind("r", hl.dsp.layout("rotatesplit"))

			-- Coarse resize for ultrawide (stay in submap, repeatable).
			-- relative = true reproduces hyprlang's `resizeactive X Y`, which is a
			-- delta; without it the Lua dispatcher treats x/y as an absolute size.
			hl.bind("right", hl.dsp.window.resize({ x =  100, y =    0, relative = true }), { repeating = true })
			hl.bind("left",  hl.dsp.window.resize({ x = -100, y =    0, relative = true }), { repeating = true })
			hl.bind("up",    hl.dsp.window.resize({ x =    0, y = -100, relative = true }), { repeating = true })
			hl.bind("down",  hl.dsp.window.resize({ x =    0, y =  100, relative = true }), { repeating = true })

			-- Very coarse resize
			hl.bind("SHIFT + right", hl.dsp.window.resize({ x =  400, y =    0, relative = true }), { repeating = true })
			hl.bind("SHIFT + left",  hl.dsp.window.resize({ x = -400, y =    0, relative = true }), { repeating = true })
			hl.bind("SHIFT + up",    hl.dsp.window.resize({ x =    0, y = -400, relative = true }), { repeating = true })
			hl.bind("SHIFT + down",  hl.dsp.window.resize({ x =    0, y =  400, relative = true }), { repeating = true })

			-- Exit
			local function exitWindowMode()
				setBorder(BORDER_NORMAL)
				hl.dispatch(hl.dsp.submap("reset"))
			end
			hl.bind("escape",    exitWindowMode)
			hl.bind("SUPER + R", exitWindowMode)
		end)

		-- Center floating window
		hl.bind("SUPER + C", hl.dsp.window.center())

		-- Pin floating window to all workspaces
		hl.bind("SUPER + SHIFT + P", hl.dsp.window.pin())

		-- Move windows between monitors
		hl.bind("SUPER + ALT + left",          hl.dsp.focus({ monitor = "-1" }))
		hl.bind("SUPER + ALT + right",         hl.dsp.focus({ monitor = "+1" }))
		hl.bind("SUPER + ALT + SHIFT + left",  hl.dsp.window.move({ monitor = "-1" }))
		hl.bind("SUPER + ALT + SHIFT + right", hl.dsp.window.move({ monitor = "+1" }))

		-- Alt-tab window cycling
		hl.bind("ALT + Tab",         hl.dsp.window.cycle_next())
		hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }))

		-- Window grouping (tabs)
		hl.bind("SUPER + G",           hl.dsp.group.toggle())
		hl.bind("SUPER + SHIFT + G",   hl.dsp.group.lock_active({ action = "toggle" }))
		hl.bind("SUPER + Tab",         hl.dsp.group.next())
		hl.bind("SUPER + SHIFT + Tab", hl.dsp.group.prev())

		-- Move focus with mainMod + arrow keys
		hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
		hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
		hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
		hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

		-- Move active window + arrowkeys
		hl.bind("SUPER + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
		hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
		hl.bind("SUPER + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
		hl.bind("SUPER + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

		-- Switch workspaces with mainMod + [0-9]
		-- Move active window to a workspace with mainMod + SHIFT + [0-9]
		for i = 1, 10 do
			local key = i % 10 -- 10 maps to key 0
			hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
			hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
		end

		-- Example special workspace (scratchpad)
		hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
		hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

		-- Scroll through existing workspaces with mainMod + scroll
		hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
		hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

		-- Move/resize windows with mainMod + LMB/RMB and dragging
		hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
		hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

		--------------------------------
		---- WINDOWS AND WORKSPACES ----
		--------------------------------

		-- Float common dialogs and popups
		local floatTitles = {
			"^(Open File)(.*)$",
			"^(Open Folder)(.*)$",
			"^(Select a File)(.*)$",
			"^(Save As)(.*)$",
			"^(Save File)(.*)$",
			"^(File Upload)(.*)$",
			"^(Confirm)(.*)$",
			"^(Authentication)(.*)$",
			"^(Preferences)$",
			"^(Properties)$",
			"^(About )(.*)$",
			"^(Print)(.*)$",
			"^(Color Picker)(.*)$",
			"^(Sign in)(.*)$",
			"^(Settings)(.*)$",
			"^(Options)(.*)$",
			"^(Warning)(.*)$",
			"^(Error)(.*)$",
			"^(Progress)(.*)$",
			"^(Export)(.*)$",
			"^(Import)(.*)$",
			"^(Update)(.*)$",
			"^(Download)(.*)$",
			-- Steam client
			"^(Steam)$",
			"^(Friends List)$",
			-- Insync
			"^(Insync)(.*)$",
		}
		for i, title in ipairs(floatTitles) do
			hl.window_rule({ name = "float-title-" .. i, match = { title = title }, float = true })
		end

		-- Float common popup app classes
		local floatClasses = {
			"^(xdg-desktop-portal)(.*)$",
			"^(polkit)(.*)$",
			"^(zenity)(.*)$",
			"^(nm-connection-editor)$",
			"^(blueman)(.*)$",
			"^(font-manager)$",
		}
		for i, class in ipairs(floatClasses) do
			hl.window_rule({ name = "float-class-" .. i, match = { class = class }, float = true })
		end

		-- Steam games → workspace 10 fullscreen
		hl.window_rule({
			name  = "steam-game",
			match = { class = "^(steam_app_.*)$" },

			workspace  = 10,
			fullscreen = true,
		})

		-- ...but NOT their launcher/splash windows. Those carry the same
		-- steam_app_* class, so the rule above would blow a 600x400 splash up to
		-- the full 5120x2160. Later rules win in Hyprland, so this one takes the
		-- fullscreen back off and floats them at their natural size.
		-- Regex is RE2: (?i) works, negative lookahead does NOT — so this is a
		-- positive list. Add whatever your games actually call their loader
		-- (find the exact title with the socket2 watcher, see note below).
		hl.window_rule({
			name  = "steam-game-launcher",
			match = {
				class = "^(steam_app_.*)$",
				title = "(?i)^.*(launcher|launch|splash|loader|updater|patcher|setup|installer|configuration|config tool|settings|options|crash).*$",
			},

			fullscreen = false,
			float      = true,
			center     = true,
		})

		-- Anarchy Online multiboxing
		-- Positioning handled by ao-launch.sh via hyprctl
		hl.window_rule({
			name  = "ao-client",
			match = { class = "^(anarchyonline\\.exe)$" },

			float   = true,
			opacity = "1.0 0.85",
		})

		-- Scratchpad
		hl.window_rule({
			name  = "scratchpad",
			match = { class = "^(scratchpad)$" },

			float     = true,
			center    = true,
			workspace = "special silent",
		})

		-- Pavucontrol
		hl.window_rule({
			name  = "pavucontrol",
			match = { class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol)$" },

			float   = true,
			size    = "50% 40%",
			center  = true,
			opacity = "0.80",
		})

		-- Thunar
		hl.window_rule({
			name  = "thunar",
			match = { class = "^(thunar)$" },

			float   = true,
			opacity = "0.90",
		})

		-- Imv
		hl.window_rule({
			name  = "imv",
			match = { class = "^(imv)$" },

			float  = true,
			size   = "70% 70%",
			center = true,
		})

		-- Opacity for certain apps
		hl.window_rule({
			name    = "app-opacity",
			match   = { class = "^(Slack|WebCord|Spotify|Kitty)$" },
			opacity = "0.9 0.9",
		})

		-- Layer rules for blur
		hl.layer_rule({
			name         = "blur-layers",
			match        = { namespace = "^(rofi|waybar|swaync)$" },
			blur         = true,
			ignore_alpha = 0.5,
		})

		-------------------
		---- AUTOSTART ----
		-------------------

		hl.on("hyprland.start", function()
			-- Initialize theme files from Nix defaults before apps start
			hl.exec_cmd([==[[ ! -f $HOME/.config/waybar/style.css ] && cp $HOME/.config/waybar/style.default.css $HOME/.config/waybar/style.css && chmod u+w $HOME/.config/waybar/style.css; [ ! -f $HOME/.config/rofi/shared/colors.rasi ] && cp $HOME/.config/rofi/shared/colors.default.rasi $HOME/.config/rofi/shared/colors.rasi && chmod u+w $HOME/.config/rofi/shared/colors.rasi; [ ! -f $HOME/.config/swaync/style.css ] && cp $HOME/.config/swaync/style.default.css $HOME/.config/swaync/style.css && chmod u+w $HOME/.config/swaync/style.css; true]==])

			hl.exec_cmd("${pkgs.awww}/bin/awww-daemon")
			hl.exec_cmd("${pkgs.waybar}/bin/waybar")
			hl.exec_cmd("${pkgs.openrazer-daemon}/bin/openrazer-daemon")
			hl.exec_cmd("${pkgs.networkmanagerapplet}/bin/nm-applet --indicator")

			-- Start CoreCtrl minimized so its saved GPU profile (undervolt / power
			-- limit) is applied at login. The real fix for this is the polkit rule in
			-- hosts/nixos-desktop/default.nix that lets CoreCtrl start its root helper
			-- without an auth prompt — without it CoreCtrl exited at boot with
			-- "Cannot start helper". --minimize-systray asks it to start with no
			-- window (minimized to the system tray), so it also needs a settled tray:
			-- the theme-switcher (run at boot) does `pkill waybar; waybar`, so we wait
			-- until Waybar's org.kde.StatusNotifierWatcher has been present
			-- continuously for ~5s (the pkill resets the counter) before launching.
			--
			-- QT_QPA_PLATFORMTHEME/QT_STYLE_OVERRIDE are unset for corectrl only: with
			-- the system-wide qt.platformTheme = "gnome" (qgnomeplatform), Qt reports
			-- "no system tray available", so --minimize-systray can't minimize and
			-- corectrl pops its WINDOW at login instead of starting silently. corectrl
			-- ignores QT_STYLE_OVERRIDE and forces its own style anyway, so dropping
			-- both for this one process costs nothing and restores the silent launch.
			-- (corectrl never registers a visible SNI tray icon here regardless — a
			-- corectrl quirk on wlroots; Steam/insync/nm-applet tray icons work fine.)
			hl.exec_cmd([==[bash -c 'unset QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE; stable=0; for i in $(seq 1 240); do if busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1; then stable=$((stable+1)); else stable=0; fi; [ "$stable" -ge 10 ] && break; sleep 0.5; done; exec ${pkgs.corectrl}/bin/corectrl --minimize-systray']==])

			hl.exec_cmd("${pkgs.hyprland-autoname-workspaces}/bin/hyprland-autoname-workspaces")
			hl.exec_cmd("pypr")
			hl.exec_cmd("wl-clipboard-history -t")
			hl.exec_cmd("wl-paste --watch cliphist store")
			hl.exec_cmd([[rm "$HOME/.cache/cliphist/db"]])   -- it'll delete history at every restart
			hl.exec_cmd("sleep 3 && ~/Scripts/awww_random.sh")
			hl.exec_cmd("sleep 4 && insync start --qt-qpa-platform=xcb --no-daemon")
			-- Restore saved theme if one was selected
			hl.exec_cmd([[sleep 2 && test -f $HOME/.config/theme/current && ~/Scripts/theme-switcher.sh $HOME/.config/theme/themes/$(cat $HOME/.config/theme/current).json]])

			hl.exec_cmd("${pkgs.hypridle}/bin/hypridle")
		end)
		'';
	in
	{
		xdg.configFile."hypr/hyprland.conf".text = hyprlandConf;
		xdg.configFile."hypr/hyprland.lua" = lib.mkIf useLua { text = hyprlandLua; };
		xdg.configFile."hypr/hyprlock.conf".text = hyprlockConf;
		xdg.configFile."hypr/hypridle.conf".text = hypridleConf;

	};
}
