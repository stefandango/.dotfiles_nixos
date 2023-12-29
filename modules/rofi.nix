{ config, lib, pkgs, home-manager, vars, ...  }:

let
inherit (config.home-manager.users.${vars.user}.lib.formats.rasi) mkLiteral;
colors = import ../theme/colors.nix;
in
{
	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				rofi-wayland
			];

			file = with colors.scheme.default.hex; {

				".config/rofi/shared/colors.rasi" = with colors.scheme.default; {
					text = ''
						* {
    background:     rgb(${rgb.bg}, 95%);
    background-alt: rgb(43, 43, 57, 95%);
    foreground:     rgb(${rgb.fg});
    selected:       rgb(${rgb.active}, 95%);
    border:         rgb(${rgb.active});
    active:         rgb(${rgb.active}, 95%);
    urgent:         rgb(${rgb.highlight});
}

					'';
				};

				".config/rofi/shared/fonts.rasi" = {
				text = ''
					/* Text Font */
* {
/*    font: "JetBrainsMono SemiBold Nerd Font Complete Mono 12"; */
font: "MonoLisaSemiBold Nerd Font Semi-Bold 12";
/* font: "JetBrainsMono Nerd Font Semi-Bold 10"; */
}
				'';
				};

				".config/rofi/launcher.rasi" = {
				 source = ./rofi/launcher.rasi;
				recursive = true;
				};

".config/rofi/powermenu.sh" = {
    source = ./rofi/powermenu.sh;
    recursive = true;
    executable = true;
		};

".config/rofi/powermenu.rasi" = {
	source = ./rofi/powermenu.rasi;
	recursive = true;
	};

".config/rofi/confirm.rasi" = {
	source = ./rofi/confirm.rasi;
	recursive = true;
	};

".config/rofi/clipboard.rasi" = {
	source = ./rofi/clipboard.rasi;
	recursive = true;
	};

		
			};	
		};

	};
}
