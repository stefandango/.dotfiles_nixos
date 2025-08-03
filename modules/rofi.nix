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
						* {
							font: "MonoLisaSemiBold Nerd Font Semi-Bold 12";
						}
					'';
				};

				".config/rofi/shared/variables.rasi" = {
					text = ''
						* {
							border-colour:               var(border);
							handle-colour:               var(selected);
							background-colour:           var(background);
							foreground-colour:           var(foreground);
							alternate-background:        var(background-alt);
							normal-background:           var(background);
							normal-foreground:           var(foreground);
							urgent-background:           var(urgent);
							urgent-foreground:           var(background);
							active-background:           var(active);
							active-foreground:           var(background);
							selected-normal-background:  var(selected);
							selected-normal-foreground:  var(background);
							selected-urgent-background:  var(active);
							selected-urgent-foreground:  var(background);
							selected-active-background:  var(urgent);
							selected-active-foreground:  var(background);
							alternate-normal-background: var(background);
							alternate-normal-foreground: var(foreground);
							alternate-urgent-background: var(urgent);
							alternate-urgent-foreground: var(background);
							alternate-active-background: var(active);
							alternate-active-foreground: var(background);
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
