{ config, lib, pkgs, home-manager, vars, ...  }:

let
inherit (config.home-manager.users.${vars.user}.lib.formats.rasi) mkLiteral;
colors = import ../../theme/colors.nix;
in
{
	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				rofi
			];

			file = with colors.scheme.default.hex; {

				".config/rofi/shared/colors.default.rasi" = with colors.scheme.default; {
					text = ''
						* {
    /* Modern glass theme with enhanced transparency */
    background:     rgb(${rgb.bg}, 85%);
    background-alt: rgba(43, 43, 57, 0.7);
    background-hover: rgba(${rgb.active}, 0.1);
    background-glass: rgba(${rgb.bg}, 0.95);
    
    foreground:     rgb(${rgb.fg});
    foreground-dim: rgba(${rgb.fg}, 0.7);
    
    selected:       rgba(${rgb.active}, 0.9);
    selected-hover: rgba(${rgb.active}, 0.95);
    
    border:         rgba(${rgb.active}, 0.8);
    border-hover:   rgba(${rgb.active}, 1.0);
    
    active:         rgba(${rgb.active}, 0.85);
    urgent:         rgba(${rgb.highlight}, 0.9);
    
    /* Modern accent colors */
    accent:         rgb(${rgb.active});
    accent-dim:     rgba(${rgb.active}, 0.5);
    
    /* Shadow effects */
    shadow:         rgba(0, 0, 0, 0.3);
}

					'';
				};

				".config/rofi/shared/fonts.rasi" = {
					text = ''
						* {
							font: "MonoLisaSemiBold Nerd Font Semi-Bold 12";
							font-large: "MonoLisaSemiBold Nerd Font Bold 14";
							font-small: "MonoLisaSemiBold Nerd Font Medium 10";
							font-icons: "MonoLisaSemiBold Nerd Font Semi-Bold 16";
							font-icons-large: "MonoLisaSemiBold Nerd Font Semi-Bold 20";
						}
					'';
				};

				".config/rofi/shared/variables.rasi" = {
					text = ''
						* {
							border-colour:               @border;
							handle-colour:               @selected;
							background-colour:           @background;
							foreground-colour:           @foreground;
							alternate-background:        @background-alt;
							normal-background:           @background;
							normal-foreground:           @foreground;
							urgent-background:           @urgent;
							urgent-foreground:           @background;
							active-background:           @active;
							active-foreground:           @background;
							selected-normal-background:  @selected;
							selected-normal-foreground:  @background;
							selected-urgent-background:  @active;
							selected-urgent-foreground:  @background;
							selected-active-background:  @urgent;
							selected-active-foreground:  @background;
							alternate-normal-background: @background;
							alternate-normal-foreground: @foreground;
							alternate-urgent-background: @urgent;
							alternate-urgent-foreground: @background;
							alternate-active-background: @active;
							alternate-active-foreground: @background;
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

".config/rofi/zones.rasi" = {
	source = ./rofi/zones.rasi;
	recursive = true;
	};


			};
		};

	};
}
