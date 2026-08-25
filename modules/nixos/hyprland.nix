{config, lib, system, pkgs, vars, host, ... }:

let
  colors = import ../../theme/colors.nix;
  # rofi leaves a stale pidfile at $XDG_RUNTIME_DIR/rofi.pid when killed via SIGTERM
  # (pkill), which then blocks every later launch with "Rofi already running" and the
  # menu dies instantly. Remove it before (re)launching so the toggle keybinds keep working.
  rofiKill = "rm -f /run/user/$(id -u)/rofi.pid; pkill rofi";
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

		# Hyprland's Lua config (0.55+). This replaced a hyprlang .conf that was kept
		# alongside as a fallback during the port; it went away once this had proven
		# itself in daily use, and is in git history if it is ever wanted back.
		#
		# Validate changes without restarting Hyprland:
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

		-- Dual Mode follower (LG 45GX950A).
		--
		-- The button under the bottom bezel flips the panel between 5K2K@165 and
		-- WFHD@330, and it is a *real hotplug*: the monitor drops off DP and comes
		-- back advertising a completely different EDID. In dual mode 5120x2160 is
		-- not offered at all (the list becomes 2560x1080@330/240/120 + 1080p).
		--
		-- The static rule above pins a custom 5120x2160@120 modeline -- 120 is not
		-- an EDID mode, it is chosen for DSC link margin on the VRR retrain and for
		-- the panel's gamma-tuned point (see the vrr = 3 note in misc below). Being
		-- a forced modeline, Hyprland keeps driving that timing into a panel that
		-- can no longer display it, so dual mode just showed the monitor's own
		-- "Out of Range" OSD -- with nothing visible to fix it with.
		--
		-- So re-pick the mode from whatever the panel actually advertises after
		-- every hotplug/reload. 5K stays capped at 120 for the reasons above; dual
		-- mode has no such history, so it takes the highest refresh on offer. If
		-- the OLED ever flickers in dual mode, cap DUAL_MAX_HZ below.
		local LG_DESC     = "LG Electronics"
		local DUAL_MAX_HZ = math.huge

		local function lgPickMode(m)
			local has5k, dual = false, nil
			for _, mode in ipairs(m.available_modes) do
				if mode.width == 5120 and mode.height == 2160 then
					has5k = true
				elseif mode.width == 2560 and mode.height == 1080 and mode.refresh_rate <= DUAL_MAX_HZ then
					if not dual or mode.refresh_rate > dual.refresh_rate then dual = mode end
				end
			end
			if has5k then return 5120, 2160, 120 end
			if dual then return dual.width, dual.height, dual.refresh_rate end
			return nil
		end

		local function lgFollowDualMode()
			for _, m in ipairs(hl.get_monitors()) do
				if m.description:find(LG_DESC, 1, true) then
					local w, h, r = lgPickMode(m)
					-- Compare numerically. hl.monitor() re-emits monitor.layout_changed,
					-- and comparing the formatted strings ("120" vs "120.00") never
					-- matches, which would re-apply the mode forever.
					local matches = w and m.width == w and m.height == h
						and math.abs(m.refresh_rate - r) < 1.0
					if w and not matches then
						hl.monitor({
							output   = "desc:" .. LG_DESC,
							mode     = string.format("%dx%d@%.2f", w, h, r),
							position = "auto",
							scale    = 1,
						})
					end
				end
			end
		end

		-- monitor.added covers the button press and the initial enumeration at
		-- startup; config.reloaded covers `hyprctl reload` re-applying the static
		-- 5K rule while the panel is in dual mode.
		hl.on("monitor.added",           lgFollowDualMode)
		hl.on("monitor.layout_changed",  lgFollowDualMode)
		hl.on("config.reloaded",         lgFollowDualMode)
		hl.on("hyprland.start",          lgFollowDualMode)

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
		xdg.configFile."hypr/hyprland.lua".text = hyprlandLua;
		xdg.configFile."hypr/hyprlock.conf".text = hyprlockConf;
		xdg.configFile."hypr/hypridle.conf".text = hypridleConf;

	};
}
