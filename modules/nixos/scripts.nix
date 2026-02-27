{ config, lib, pkgs, home-manager, vars, ...  }:

let
in
{
	home-manager.users.${vars.user} = {
		home = {

			file = {
			"Scripts/swaylock.sh" = {
				source = ../scripts/swaylock.sh;
				recursive = true;
				executable = true;
			};
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
			"Scripts/swww_random.sh" = {	
				source = ../scripts/swww_random.sh;
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
			# Theme JSON files
			".config/theme/themes/onedark.json".source = ../../theme/themes/onedark.json;
			".config/theme/themes/doom.json".source = ../../theme/themes/doom.json;
			".config/theme/themes/dracula.json".source = ../../theme/themes/dracula.json;
			".config/theme/themes/catppuccin-mocha.json".source = ../../theme/themes/catppuccin-mocha.json;
			".config/theme/themes/catppuccin-latte.json".source = ../../theme/themes/catppuccin-latte.json;
			".config/theme/themes/nord.json".source = ../../theme/themes/nord.json;
			".config/theme/themes/gruvbox-dark.json".source = ../../theme/themes/gruvbox-dark.json;
			".config/theme/themes/tokyo-night.json".source = ../../theme/themes/tokyo-night.json;
			".config/theme/themes/rose-pine.json".source = ../../theme/themes/rose-pine.json;
			".config/theme/themes/afterglow.json".source = ../../theme/themes/afterglow.json;
			".config/theme/themes/github-light.json".source = ../../theme/themes/github-light.json;
			".config/theme/themes/solarized-light.json".source = ../../theme/themes/solarized-light.json;
			".config/theme/themes/rose-pine-dawn.json".source = ../../theme/themes/rose-pine-dawn.json;
			".config/theme/themes/catppuccin-frappe.json".source = ../../theme/themes/catppuccin-frappe.json;

			};
		};

	};
}
