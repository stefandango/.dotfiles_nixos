{ config, lib, pkgs, home-manager, vars, ...  }:

let
in
{
	home-manager.users.${vars.user} = {
		home = {

			file = {
			"Scripts/viper_battery.py" = {
				source = ../scripts/viper_battery.py;
				recursive = true;
				executable = true;
			};
			"Scripts/tailscale-peers.sh" = {
				source = ../scripts/tailscale-peers.sh;
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

			"Scripts/gamemode-toggle.sh" = {
				source = ../scripts/gamemode-toggle.sh;
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
			# rebuild would move. `--json` feeds the DMS nixosUpdates widget; a bare
			# call prints the terminal panel the pyprland scratchpad shows.
			"Scripts/nixupdates" = {
				source = ../scripts/nixupdates;
				recursive = true;
				executable = true;
			};
			# Syncs ~/.config/DankMaterialShell/plugins against the lockfile in
			# modules/config/dms-plugins.lock.json. Kept out of home.activation on
			# purpose — restoring git-clones the plugins, and nixswitch should not
			# need the network.
			"Scripts/dmsplugins" = {
				source = ../scripts/dmsplugins;
				recursive = true;
				executable = true;
			};

			};
		};

	};
}
