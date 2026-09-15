{config, lib, system, pkgs, vars, host, ... }:

let
  # The binds that reach into the shell rather than the compositor.
  # DankMaterialShell owns all of them, so each is an IPC call into the
  # already-running shell process rather than a program launch.
  shellBinds = ''
		-- DankMaterialShell owns the launcher, clipboard, notification centre,
		-- lock screen and power menu. Each of these is an IPC call into the
		-- already-running shell process, not a fresh program launch — so there is
		-- no cold start.
		hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
		-- spotlight-bar is a genuinely different surface from `spotlight`:
		-- a slim one-line prompt with no results list until you type, where
		-- SUPER+D opens the full panel. (`launcher` is NOT a third option --
		-- DMSShellIPC.qml aliases it to `spotlight` for backwards compat.)
		hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("dms ipc call spotlight-bar toggle"))
		hl.bind("SUPER + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
		hl.bind("SUPER + N", hl.dsp.exec_cmd("dms ipc call notifications toggle"))
		hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
		hl.bind("SUPER + Y", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
		hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("dms ipc call settings open"))
		-- DMS generates its keybind reference from the live binds, unlike our
		-- hand-maintained cheatsheet.sh (which had already drifted from reality).
		hl.bind("SUPER + SHIFT + plus", hl.dsp.exec_cmd("dms ipc call keybinds toggle"))
		hl.bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("dms ipc call control-center toggle"))
		-- Wallpaper Carousel is a PLUGIN, so this bind is dead until
		-- `~/Scripts/dmsplugins` has restored it from the lockfile. DMS is the
		-- sole wallpaper manager now, and this replaced awww's 300s shuffle --
		-- which had been drawing a second background layer underneath DMS's,
		-- invisible but still reshuffling. Wallpaper cycling is deliberately
		-- off: the palette is derived from the wallpaper, so a timed shuffle
		-- would recolour the whole desktop every few minutes.
		hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("dms ipc call wallpaperCarousel toggle"))
		-- Opens the nixosUpdates popout without having to aim at the pill. The id
		-- resolves through BarWidgetService, so this only works while the widget
		-- is actually on the bar -- and the pill hides itself when up to date,
		-- which is exactly when you would reach for the keybind instead.
		hl.bind("SUPER + U", hl.dsp.exec_cmd("dms ipc call widget toggle nixosUpdates"))
  '';

  # DMS has no submap indicator -- HyprlandService.qml carries no submap
  # support at all -- so SUPER+Q would arm the kill submap with nothing on
  # screen to say so. A DMS toast fills the gap: themed like the rest of the
  # shell and dropped from the top edge under the island, rather than
  # Hyprland's own hl.notification overlay, which is unstyled and corner-bound.
  killPrompt = ''
		local function killPromptShow()
			hl.exec_cmd([[dms ipc call toast errorWith "Kill window?" "Q or Enter to confirm  ·  Esc to cancel" "" "submap"]])
		end
		local function killPromptHide()
			hl.exec_cmd("dms ipc call toast dismiss submap")
		end
  '';
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
			grimblast       	# Screenshot, bound to `print`
			wl-clipboard    	# wl-copy, used by scripts (DMS owns the history)
			wlr-randr       	# Monitor Settings
			networkmanagerapplet	# SNI tray + NetworkManager auth/VPN dialogs
			insync			# Gdrive integration
			thunar			# File explorer GUI
			thunar-volman		# Auto manage removable drives etc..
			imv			# Simple image viewer

			# notify-send, used by scripts and by grimblast --notify. The daemon
			# behind org.freedesktop.Notifications is DMS.
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
	};
	systemd.sleep.settings.Sleep = {
		AllowSuspend = "no";
		AllowHibernation = "no";
		AllowSuspendThenHibernate = "no";
		AllowHybridSleep = "yes";
	};

	home-manager.users.${vars.user} =
	let


		# Hyprland's Lua config (0.55+). This replaced a hyprlang .conf that was kept
		# alongside as a fallback during the port; it went away once this had proven
		# itself in daily use, and is in git history if it is ever wanted back.
		#
		# Validate changes without restarting Hyprland:
		#   Hyprland --verify-config -c <file> 2>&1 | grep -q '^config ok$'
		# (the exit code is always 1, so the "config ok" line is the only signal;
		# it does catch unknown config keys and unknown rule fields, with line
		# numbers, but not wrong values inside layoutmsg strings.)
		# Compositor chrome. Deliberately static rather than matugen-derived:
		# these are a 1px border and a groupbar, they are reapplied at runtime by
		# setBorder() (which would overwrite anything a template wrote), and the
		# submap colour is semantic -- a "this is armed" warning wants to stay warm
		# and distinct however the wallpaper shifts. Neutral values chosen to sit
		# with matugen's scheme-neutral output rather than fight it.
		hyprlandLua = with {
			borderActive   = "bac9d1";   # matugen scheme-neutral primary
			borderActive2  = "8b9aa3";   # dimmer, so the 45deg gradient still reads
			borderInactive = "4a4a52";
			submapWarn     = "c2a15c";   # kill-submap armed: warm on purpose
			submapWarn2    = "bd8b5e";
			groupActive    = "bac9d1";
			bg             = "121314";   # matugen scheme-neutral background
		};
		''
		------------------
		---- MONITORS ----
		------------------

		-- LG 45" ultrawide (update desc: string from hyprctl monitors if needed)
		--
		-- Note: on a hotplug Hyprland re-applies the monitor's *previous* mode
		-- before any rule or handler gets a look in, so every dual-mode
		-- transition briefly drives an out-of-range timing (the old 5K modeline
		-- at a 2560x1080 panel, or vice versa) no matter what this rule says.
		-- Setting it to "preferred" was tried and changes nothing -- the stray
		-- modeset comes from Hyprland's state restore, not from here.
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
		-- Capped so dual mode lands on 2560x1080@240.08, not the panel's @330.12.
		--
		-- 330 does not survive this link. amdgpu drives dual mode *uncompressed*
		-- (dsc_clock_en = 0) over HBR3 x4, putting ~24 of the available 25.9 Gbps
		-- on the wire -- about 93% utilisation, so no margin. The DP payload
		-- handshake then fails ("SST Update Payload: ACT still not handled ...
		-- Link loss occurred"), the connector drops, and after two retries the
		-- panel gives up and reverts to 5K -- which presents as the button
		-- instantly blanking the screen. 240 needs only ~17 Gbps and is stable.
		--
		-- Confirmed 2026-09-09. Not a kernel regression to wait out: 7.2.3 and
		-- 7.2.4 fail identically. Not the config either -- the follower picks
		-- correctly, and Hyprland re-applies the previous mode on reconnect
		-- before any rule runs, so the out-of-range transient is unavoidable and
		-- was equally present back when 330 did work.
		--
		-- Not a hardware ceiling either: link_settings reports UHBR13.5 (0x546)
		-- verified on this link, but amdgpu stays on HBR3 because 330 fits on
		-- paper. Raising DUAL_MAX_HZ needs either a forced preferred link rate
		-- via .../DP-*/link_settings in debugfs, or a cable with better margin.
		-- Capped at 240 (picks 2560x1080@240.08, not the panel's @330.12).
		-- 330 does NOT hold on this link and a premium DP cable did not change that
		-- (tested 2026-09-11): amdgpu drives dual mode uncompressed over HBR3 x4 at
		-- ~93% bandwidth, the DP payload handshake fails ("SST Update Payload ...
		-- branch" / "Link loss"), and the panel reverts to 5K -- i.e. a black flash,
		-- self-recovered. It is a hard bandwidth wall, not signal margin: the fix
		-- would be amdgpu stepping up to the UHBR rate the link reports as verified,
		-- but it will not, and forcing DP 2.1 in the monitor OSD black-screens on
		-- this RDNA4 (RX 9070 XT) driver. 240 needs ~17 of 25.9 Gbps and is solid.
		local DUAL_MAX_HZ = 250

		-- Ground truth for which EDID is live *right now*, read straight from the
		-- kernel. hl.get_monitors() lags a hotplug by several event rounds:
		-- monitor.added fires while available_modes still describes the panel's
		-- previous state. Trusting that stale list is what turned a dual -> 5K
		-- transition into an instant black screen -- the handler saw the outgoing
		-- dual list, re-applied 2560x1080@330 to a panel already back in 5K, and
		-- only recovered when layout_changed came round again with fresh data.
		-- The kernel has already updated sysfs by the time it emits the udev
		-- hotplug Hyprland is reacting to, so this never lags.
		local function lgDrmModes(name)
			for _, card in ipairs({ "card0", "card1", "card2" }) do
				local f = io.open("/sys/class/drm/" .. card .. "-" .. name .. "/modes", "r")
				if f then
					local s = f:read("*a")
					f:close()
					if s and s ~= "" then return s end
				end
			end
			return nil
		end

		local function lgPickMode(m)
			local has5k, dual = false, nil
			for _, mode in ipairs(m.available_modes) do
				if mode.width == 5120 and mode.height == 2160 then
					has5k = true
				elseif mode.width == 2560 and mode.height == 1080 and mode.refresh_rate <= DUAL_MAX_HZ then
					if not dual or mode.refresh_rate > dual.refresh_rate then dual = mode end
				end
			end

			local kmodes = lgDrmModes(m.name)
			if not kmodes then
				-- No ground truth available (unexpected card numbering, say): fall
				-- back to Hyprland's list and accept the stale-read race.
				if has5k then return 5120, 2160, 120 end
				if dual then return dual.width, dual.height, dual.refresh_rate end
				return nil
			end

			-- The two EDIDs are disjoint, so one substring settles which is live.
			if kmodes:find("5120x2160", 1, true) then
				-- 5K's refresh is pinned, so this needs nothing from the stale list.
				return 5120, 2160, 120
			end
			if kmodes:find("2560x1080", 1, true) and dual then
				-- Dual mode *does* need a refresh rate out of that list, so only act
				-- once kernel and Hyprland agree. A disagreement just means Hyprland
				-- has not caught up; the next event carries fresh data.
				return dual.width, dual.height, dual.refresh_rate
			end
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
		local BORDER_NORMAL   = { colors = { "rgba(${borderActive}ee)", "rgba(${borderActive2}ee)" }, angle = 45 }
		local BORDER_WINDOW   = { colors = { "rgba(${submapWarn}ee)", "rgba(${submapWarn2}ee)" }, angle = 45 }
		local BORDER_INACTIVE = "rgba(${borderInactive}aa)"

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
					border_active   = "rgba(${borderActive}ee)",
					border_inactive = "rgba(${borderInactive}aa)",
				},

				groupbar = {
					enabled       = true,
					font_size     = 14,
					height        = 30,
					render_titles = true,
					col = {
						active   = "rgb(${groupActive})",
						inactive = "rgb(${borderInactive})",
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
				-- the DP-disconnect SIGSEGV, seen on DP-2 before the 2026-09-07 port swap)
				-- AND matches the panel's gamma-tuned point.
				--
				-- Every VRR entry/exit is a DP link re-train, which is why this setting is
				-- load-bearing rather than cosmetic: on a marginal link each re-train is a
				-- chance to lose it outright. See the DP 2.1 UHBR note in the host's
				-- kernelParams for the 2026-09-07 black-screen incident.
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

		hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))

		-- Kill submap: SUPER+Q arms it, then Q or Return confirms.
${killPrompt}
		-- The prompt is the only thing saying the kill is armed, and DMS's error
		-- toast lives 5s, so the submap expires on the same clock. Previously it
		-- stayed armed indefinitely: a forgotten SUPER+Q meant the next stray Q
		-- closed a window with no warning at all.
		local killTimer = nil
		local function killDisarm()
			if killTimer then
				killTimer:set_enabled(false)
				killTimer = nil
			end
			killPromptHide()
			hl.dispatch(hl.dsp.submap("reset"))
		end

		hl.bind(mainMod .. " + Q", function()
			if killTimer then killTimer:set_enabled(false) end
			killPromptShow()
			killTimer = hl.timer(killDisarm, { timeout = 5000, type = "oneshot" })
			hl.dispatch(hl.dsp.submap("kill"))
		end)

		hl.define_submap("kill", function()
			-- hyprlang stacked two binds on one key (killactive, then submap reset);
			-- in Lua a single function does both, with unambiguous ordering.
			local function killAndReset()
				hl.dispatch(hl.dsp.window.close())
				killDisarm()
			end
			hl.bind("Q",        killAndReset)
			hl.bind("Return",   killAndReset)
			hl.bind("escape",   killDisarm)
			hl.bind("catchall", killDisarm)
		end)

		hl.bind("SUPER + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
${shellBinds}
		hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())       -- dwindle
		hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle (0.54+: via layoutmsg)
		hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("${pkgs.hyprland}/bin/hyprctl reload"))
		hl.bind("SUPER + F", hl.dsp.window.fullscreen())
		hl.bind("print", hl.dsp.exec_cmd([[${pkgs.grimblast}/bin/grimblast --notify --freeze --wait 1 copysave area ~/Pictures/$(date +%Y-%m-%dT%H%M%S).png]]))
		-- Was `code:49` under hyprlang. The Lua bind parser silently swallows
		-- `code:NN` (0.56.1 registers the bind with an empty key and keycode 0, so it
		-- never fires), so this uses the keysym. Keycode 49 is <TLDE>, which on the
		-- dk layout set above is `onehalf` (½) — layout-dependent, unlike code:.
		hl.bind("SUPER + onehalf", hl.dsp.exec_cmd("pypr toggle term"))
		hl.bind("SUPER + Z", hl.dsp.exec_cmd("pypr zoom"))
		hl.bind("SUPER + E", hl.dsp.exec_cmd("pypr toggle files"))
		hl.bind("SUPER + I", hl.dsp.exec_cmd("~/Scripts/imv_launcher.sh"))
		hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("~/Scripts/focus-mode-toggle.sh"))

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
			-- DMS namespaces every layer surface "dms:<something>" (dms:bar,
			-- dms:clipboard-context-menu, ...), so it needs its own alternative —
			-- a namespace that does not match here silently loses blur.
			match        = { namespace = "^dms:.*$" },
			blur         = true,
			-- The spotlight's fullscreen scrim sits at exactly opacity 0.5
			-- (DankLauncherV2ModalSpotlight.qml), so at ignore_alpha = 0.5 whether
			-- the whole 5120x2160 surface takes a 2-pass blur every frame comes
			-- down to a float compare landing the right way. 0.6 puts the scrim
			-- clearly under the threshold; the cards are at popupTransparency 0.96
			-- and still blur.
			ignore_alpha = 0.6,
		})

		-- With a transparent bar over translucent widget cards, blur that samples
		-- the windows underneath turns muddy as soon as anything is maximised.
		-- xray makes it sample the wallpaper instead, so the cards stay legible.
		-- DMS generates this same rule into ~/.config/hypr/dms/layout.lua, which
		-- our Nix-generated hyprland.lua deliberately does not source.
		hl.layer_rule({
			name  = "dms-bar-xray",
			match = { namespace = "^dms:bar$" },
			xray  = true,
		})

		-- DMS animates every surface it maps itself (the spotlight opens over
		-- _openDuration = 50ms, popouts over Theme.popoutAnimationDuration), so
		-- Hyprland's own layer animation is a second, slower curve wrapped around
		-- the first. `layers` is not overridden anywhere in this file, so it
		-- inherits `global` -- speed 8 with the `default` bezier, ~80ms -- and the
		-- two curves fighting is what reads as sluggish on SUPER+SPACE, not any
		-- single slow step. Hand the motion back to DMS.
		hl.layer_rule({
			name    = "dms-noanim",
			match   = { namespace = "^dms:.*$" },
			no_anim = true,
		})

		-------------------
		---- AUTOSTART ----
		-------------------

		hl.on("hyprland.start", function()
			-- One process for bar, notifications, launcher, OSD, lock, polkit and
			-- wallpaper. Started here rather than as a systemd user unit: the unit
			-- binds graphical-session.target by default, which this machine's plain
			-- (non-UWSM) Hyprland session never activates — see modules/nixos/ntfy.nix.
			-- (programs.hyprland.withUWSM is true, but the session that actually runs
			-- is bin/start-hyprland; if that is ever reconciled, the packaged
			-- dms.service would start alongside this line.)
			hl.exec_cmd("dms run")
			hl.exec_cmd("${pkgs.openrazer-daemon}/bin/openrazer-daemon")
			hl.exec_cmd("${pkgs.networkmanagerapplet}/bin/nm-applet --indicator")


			hl.exec_cmd("pypr")
			hl.exec_cmd("sleep 4 && insync start --qt-qpa-platform=xcb --no-daemon")
		end)
		'';
	in
	{
		xdg.configFile."hypr/hyprland.lua".text = hyprlandLua;

	};
}
