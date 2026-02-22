
{ config, lib, pkgs, home-manager, vars, ...  }:

let
inherit (config.home-manager.users.${vars.user}.lib.formats.rasi) mkLiteral;
colors = import ../../theme/colors.nix;
in
{
	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				waybar
				jq
			];

			file = with colors.scheme.default.hex; {


				".config/waybar/config" = {
					source = ./waybar/config;
					recursive = true;
				};



				".config/waybar/style.default.css".text = with colors.scheme.default; ''
					* {
						border: none;
						border-radius: 0;
						font-family: "MonoLisa Nerd Font", "JetBrainsMono Nerd Font", monospace;
						font-weight: 500;
						font-size: 13px;
						min-height: 0;
					}

					window#waybar {
						background: rgba(${rgb.bg}, 0.85);
						color: #${hex.fg};
						transition-property: background-color;
						transition-duration: 0.3s;
						border-radius: 0;
						margin: 0;
						padding: 0;
					}

					tooltip {
						background: rgba(${rgb.bg}, 0.95);
						color: #${hex.fg};
						border-radius: 8px;
						border: 2px solid #${hex.active};
						padding: 8px;
					}

					#workspaces {
						padding: 2px 6px;
						margin: 2px 6px;
						background: transparent;
						border: none;
						border-radius: 8px;
					}

					#workspaces button {
						padding: 4px 8px;
						color: #${hex.text};
						background: transparent;
						border: none;
						border-radius: 6px;
						margin: 0 1px;
						transition: all 0.2s ease;
						font-weight: 500;
						min-width: 28px;
					}

					#workspaces button.active {
						color: #${hex.fg};
						background: rgba(${rgb.active}, 0.6);
						border: none;
						box-shadow: 0 2px 8px rgba(${rgb.active}, 0.2);
					}

					#workspaces button:hover {
						background: rgba(${rgb.fg}, 0.2);
						color: #${hex.fg};
					}

					#workspaces button.urgent {
						color: #${hex.red};
						background: rgba(${rgb.red}, 0.3);
						border: none;
					}

					#clock,
					#custom-weather,
					#custom-docker,
					#custom-clipboard,
					#custom-razerviperbattery,
					#custom-disks,
					#memory,
					#cpu,
					#temperature,
					#pulseaudio,
					#network,
					#tray,
					#custom-notification,
					#custom-logout {
						padding: 4px 8px;
						margin: 2px 3px;
						color: #${hex.fg};
						background: transparent;
						border: none;
						border-radius: 6px;
						transition: all 0.2s ease;
					}

					#clock:hover,
					#custom-weather:hover,
					#custom-docker:hover,
					#custom-clipboard:hover,
					#custom-razerviperbattery:hover,
					#custom-disks:hover,
					#memory:hover,
					#cpu:hover,
					#temperature:hover,
					#pulseaudio:hover,
					#network:hover,
					#custom-notification:hover,
					#custom-logout:hover {
						background: rgba(${rgb.active}, 0.2);
					}

					#clock {
						color: #${hex.fg};
						font-weight: bold;
						min-width: 80px;
					}

					#custom-weather {
						color: #${hex.blue};
					}

					#custom-docker {
						color: #${hex.green};
					}

					#custom-clipboard {
						color: #${hex.purple};
					}

					#custom-memory {
						color: #${hex.orange};
					}

					#custom-cpu {
						color: #${hex.yellow};
					}

					#custom-temperature {
						color: #${hex.red};
					}

					#temperature.critical {
						color: #${hex.red};
						background: rgba(${rgb.red}, 0.2);
					}


					#pulseaudio {
						color: #${hex.purple};
					}

					#pulseaudio.muted {
						color: #${hex.gray};
					}

					#network {
						color: #${hex.green};
					}

					#network.disconnected {
						color: #${hex.red};
					}

					#custom-logout {
						color: #${hex.red};
						font-weight: bold;
					}

					#custom-logout:hover {
						background: rgba(${rgb.red}, 0.2);
						border-color: #${hex.red};
					}

					#custom-razerviperbattery {
						color: #${hex.yellow};
					}

					#custom-notification {
						color: #${hex.fg};
					}

					#custom-devserver {
						color: #${hex.cyan};
					}

					#custom-tmux {
						color: #${hex.text};
					}

					#tray {
						padding: 4px 8px;
						background: rgba(${rgb.bg}, 0.8);
						border: 1px solid rgba(${rgb.active}, 0.5);
						border-radius: 6px;
					}

					#tray > .passive {
						-gtk-icon-effect: dim;
					}

					#tray > .needs-attention {
						-gtk-icon-effect: highlight;
						background-color: #${hex.red};
					}
				'';

				".config/hyprland-autoname-workspaces/config.toml" = {
					source = ./waybar/config.toml;
					recursive = true;
				};
		
			};	
		};

	};
}
