{ config, lib, pkgs, home-manager, vars, ...  }:

let
in
{
	home-manager.users.${vars.user} = {
		home = {

			file = {
			"Scripts/waybar-wttr.py" = {
				source = ../scripts/waybar-wttr.py;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-diskinfo.sh" = {
				source = ../scripts/waybar-diskinfo.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/viper_battery.py" = {
				source = ../scripts/viper_battery.py;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-docker.sh" = {
				source = ../scripts/waybar-docker.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-llama.sh" = {
				source = ../scripts/waybar-llama.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-tailscale.sh" = {
				source = ../scripts/waybar-tailscale.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/tailscale-peers.sh" = {
				source = ../scripts/tailscale-peers.sh;
				recursive = true;
				executable = true;
			};
				
			"Scripts/waybar-clipboard.sh" = {
				source = ../scripts/waybar-clipboard.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-submap.sh" = {
				source = ../scripts/waybar-submap.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/awww_random.sh" = {
				source = ../scripts/awww_random.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/imv_launcher.sh" = {
				source = ../scripts/imv_launcher.sh;
				recursive = true;
				executable = true;
			};
			#"Scripts/tmux-sessionizer" = {
			#	source = ../scripts/tmux-sessionizer;
			#	recursive = true;
			#	executable = true;
			#};
			"Scripts/tmux-quit" = {
				source = ../scripts/tmux-quit;
				recursive = true;
				executable = true;
			};

			"Scripts/waybar-gamemode.sh" = {
				source = ../scripts/waybar-gamemode.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/gamemode-toggle.sh" = {
				source = ../scripts/gamemode-toggle.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/theme-switcher.sh" = {
				source = ../scripts/theme-switcher.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/theme-rofi.sh" = {
				source = ../scripts/theme-rofi.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/focus-mode-toggle.sh" = {
				source = ../scripts/focus-mode-toggle.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/focus-mode-daemon.sh" = {
				source = ../scripts/focus-mode-daemon.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/cheatsheet.sh" = {
				source = ../scripts/cheatsheet.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-focusmode.sh" = {
				source = ../scripts/waybar-focusmode.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-tmux.sh" = {
				source = ../scripts/waybar-tmux.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-cpu.sh" = {
				source = ../scripts/waybar-cpu.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-temperature.sh" = {
				source = ../scripts/waybar-temperature.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-memory.sh" = {
				source = ../scripts/waybar-memory.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-devserver.sh" = {
				source = ../scripts/waybar-devserver.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/ao-launch.sh" = {
				source = ../scripts/ao-launch.sh;
				recursive = true;
				executable = true;
			};
			# Sourced by theme-switcher / focus-mode / ao-launch, and run directly
			# by hypridle and swaync. Wraps the `hyprctl eval` / Lua-dispatch forms
			# that Hyprland's Lua config manager requires.
			"Scripts/hypr-compat.sh" = {
				source = ../scripts/hypr-compat.sh;
				recursive = true;
				executable = true;
			};
			# How far the pinned nixpkgs is behind its branch, and which packages a
			# rebuild would move. `--json` feeds the DMS nixosUpdates widget,
			# `--waybar` the custom/updates module on the waybar path; a bare call
			# prints the terminal panel the pyprland scratchpad shows.
			"Scripts/nixupdates" = {
				source = ../scripts/nixupdates;
				recursive = true;
				executable = true;
			};
			"Scripts/omarchy-menu.sh" = {
				source = ../scripts/omarchy-menu.sh;
				recursive = true;
				executable = true;
			};
			# Syncs ~/.config/DankMaterialShell/plugins against the lockfile in
			# modules/config/dms-plugins.lock.json. Kept out of home.activation on
			# purpose — restoring git-clones the plugins, and nixswitch should not
			# need the network. Only useful while desktopShell = "dms".
			"Scripts/dmsplugins" = {
				source = ../scripts/dmsplugins;
				recursive = true;
				executable = true;
			};
			# Theme JSON files — curated "Graphite" family: one neutral dark base,
			# only the accent (and neutral temperature) shifts between variants.
			".config/theme/themes/graphite.json".source = ../../theme/themes/graphite.json;
			".config/theme/themes/slate.json".source = ../../theme/themes/slate.json;
			".config/theme/themes/umber.json".source = ../../theme/themes/umber.json;
			".config/theme/themes/moss.json".source = ../../theme/themes/moss.json;
			".config/theme/themes/mono.json".source = ../../theme/themes/mono.json;

			};
		};

	};
}
