
{ config, lib, pkgs, home-manager, vars, ...  }:

let
inherit (config.home-manager.users.${vars.user}.lib.formats.rasi) mkLiteral;
colors = import ../theme/colors.nix;
in
{
	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				waybar
			];

			file = with colors.scheme.default.hex; {


				".config/waybar/config" = {
					source = ./waybar/config;
					recursive = true;
				};



				".config/waybar/style.css" = {
					source = ./waybar/style.css;
					recursive = true;
				};

		
			};	
		};

	};
}
