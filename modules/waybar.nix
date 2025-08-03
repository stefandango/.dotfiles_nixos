
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
				jq
			];

			file = with colors.scheme.default.hex; {


				".config/waybar/config" = {
					source = ./waybar/config;
					recursive = true;
				};



				".config/waybar/style.css".text = with colors.scheme.default; ''
					* {
						border: none;
						border-radius: 0;
						font-family: "MonoLisa Nerd Font", "JetBrainsMono Nerd Font", monospace;
						font-weight: 600;
						font-size: 12px;
						min-height: 0;
					}

					window#waybar {
						background: transparent;
						color: #${hex.fg};
						transition-property: background-color;
						transition-duration: 0.5s;
					}

					tooltip {
						background: rgba(${rgb.bg}, 0.95);
						color: #${hex.fg};
						border-radius: 8px;
						border: 2px solid #${hex.active};
						padding: 8px;
					}

					#workspaces {
						padding: 4px 8px;
						margin: 2px 4px;
						background: rgba(${rgb.bg}, 0.8);
						border: 1px solid rgba(${rgb.active}, 0.5);
						border-radius: 6px;
					}

					#workspaces button {
						padding: 6px 12px;
						color: #${hex.text};
						background: transparent;
						border: none;
						border-radius: 6px;
						margin: 0 2px;
						transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
						font-weight: 500;
						min-width: 32px;
					}

					#workspaces button.active {
						color: #${hex.fg};
						background: rgba(${rgb.active}, 0.4);
						border: 1px solid #${hex.active};
						box-shadow: 0 2px 4px rgba(${rgb.active}, 0.3);
					}

					#workspaces button:hover {
						background: rgba(${rgb.fg}, 0.15);
						color: #${hex.fg};
					}

					#workspaces button.urgent {
						color: #${hex.red};
						background: rgba(${rgb.red}, 0.2);
						border: 1px solid #${hex.red};
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
						margin: 2px 4px;
						color: #${hex.fg};
						background: rgba(${rgb.bg}, 0.8);
						border: 1px solid rgba(${rgb.active}, 0.5);
						border-radius: 6px;
						transition: all 0.3s ease-in-out;
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
						border-color: #${hex.active};
					}

					#clock {
						color: #${hex.cyan};
						font-weight: bold;
						min-width: 80px;
					}

					#custom-weather {
						color: #${hex.blue};
					}

					#custom-docker {
						color: #${hex.blue};
					}

					#custom-clipboard {
						color: #${hex.purple};
					}

					#memory {
						color: #${hex.green};
					}

					#cpu {
						color: #${hex.yellow};
					}

					#temperature {
						color: #${hex.orange};
					}

					#temperature.critical {
						color: #${hex.red};
						background: rgba(${rgb.red}, 0.2);
						border-color: #${hex.red};
					}

					#pulseaudio {
						color: #${hex.cyan};
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
						color: #${hex.cyan};
					}

					#custom-notification {
						color: #${hex.blue};
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
