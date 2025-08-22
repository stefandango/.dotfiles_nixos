{ config, lib, pkgs, home-manager, vars, ...  }:

let
in
{
	home-manager.users.${vars.user} = {
		home = {

			file = {
			"Scripts/swaylock.sh" = {
				source = ./scripts/swaylock.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-wttr.py" = {
				source = ./scripts/waybar-wttr.py;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-diskinfo.sh" = {
				source = ./scripts/waybar-diskinfo.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/viper_battery.py" = {
				source = ./scripts/viper_battery.py;
				recursive = true;
				executable = true;
			};
			"Scripts/waybar-docker.sh" = {
				source = ./scripts/waybar-docker.sh;
				recursive = true;
				executable = true;
			};
				
			"Scripts/waybar-clipboard.sh" = {
				source = ./scripts/waybar-clipboard.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/swww_random.sh" = {	
				source = ./scripts/swww_random.sh;
				recursive = true;
				executable = true;
			};
			"Scripts/imv_launcher.sh" = {
				source = ./scripts/imv_launcher.sh;
				recursive = true;
				executable = true;
			};
			#"Scripts/tmux-sessionizer" = {
			#	source = ./scripts/tmux-sessionizer;
			#	recursive = true;
			#	executable = true;
			#};
			"Scripts/tmux-quit" = {
				source = ./scripts/tmux-quit;
				recursive = true;
				executable = true;
			};

			};	
		};

	};
}
