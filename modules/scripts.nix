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
			"Scripts/viper_batter.py" = {
				source = ./scripts/viper_battery.py;
				recursive = true;
				executable = true;
			};
				
			};	
		};

	};
}
