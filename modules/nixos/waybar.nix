
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
				socat
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
						/* Inter for text (clean UI sans); MonoLisa Nerd Font fallback supplies the icon glyphs. */
						font-family: "Inter", "MonoLisa Nerd Font", "JetBrainsMono Nerd Font", monospace;
						font-weight: 600;
						font-size: 13px;
						/* tabular figures — keeps the clock and %/value modules from width-jittering.
						   GTK3 wants the bare tag; "tnum" 1 is rejected ("Junk at end of value"). */
						font-feature-settings: "tnum";
						/* very subtle optical tracking; the real icon↔text gap is the double-space
						   separator baked into the module formats/scripts, not letter-spacing. */
						letter-spacing: 0.3px;
						min-height: 0;
					}

					window#waybar {
						background: transparent;
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
						margin: 4px 8px;
						background: rgba(${rgb.bg}, 0.85);
						border: none;
						border-left: 3px solid rgba(${rgb.gray}, 0.5);
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
						background: rgba(${rgb.accent}, 0.55);
						border: none;
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
					#custom-llama,
					#custom-updates,
					#custom-clipboard,
					#custom-tmux,
					#custom-razerviperbattery,
					#custom-focusmode,
				#custom-gamemode,
					#custom-disks,
					#memory,
					#cpu,
					#temperature,
					#pulseaudio,
					#network,
					#tray,
					#custom-notification,
					#custom-logout {
						padding: 4px 10px;
						margin: 2px 4px;
						color: #${hex.fg};
						background: transparent;
						border: none;
						border-radius: 6px;
						transition: all 0.2s ease;
					}

					#clock:hover,
					#custom-weather:hover,
					#custom-docker:hover,
					#custom-llama:hover,
					#custom-updates:hover,
					#custom-clipboard:hover,
					#custom-tmux:hover,
					#custom-razerviperbattery:hover,
					#custom-focusmode:hover,
				#custom-gamemode:hover,
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

					#custom-submap {
						color: #${hex.bg};
						font-weight: bold;
						font-size: 14px;
						padding: 4px 14px;
						border-radius: 8px;
						margin: 2px 6px;
					}

					#custom-submap.window {
						background: #${hex.warning};
					}

					#custom-submap.kill {
						background: #${hex.danger};
						padding: 4px 30px;
						margin: 2px 8px;
					}

					#custom-submap.empty {
						padding: 0;
						margin: 0;
					}

					#clock {
						color: #${hex.fg};
						font-weight: bold;
						min-width: 200px;
					}

					#custom-weather {
						color: #${hex.fg};
						background: rgba(${rgb.bg}, 0.85);
						border: none;
						border-left: 3px solid rgba(${rgb.gray}, 0.5);
						border-radius: 8px;
						margin: 4px 8px;
					}

					#custom-docker {
						color: #${hex.fg};
					}

					#custom-docker.inactive {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-llama {
						color: #${hex.fg};
					}

					#custom-llama.active {
						color: #${hex.success};
					}

					#custom-llama.idle {
						color: #${hex.gray};
					}

					#custom-updates {
						color: #${hex.fg};
					}

					#custom-updates.current {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-updates.updates {
						color: #${hex.warning};
						background: rgba(${rgb.warning}, 0.1);
						border: 1px solid rgba(${rgb.warning}, 0.4);
						border-radius: 10px;
						padding: 2px 14px 2px 18px;
					}

					#custom-updates.checking {
						color: #${hex.gray};
					}

					#custom-clipboard {
						color: #${hex.fg};
					}

					#custom-memory {
						color: #${hex.fg};
					}

					#custom-memory.normal {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-memory.warning {
						color: #${hex.orange};
					}

					#custom-memory.critical {
						color: #${hex.red};
						background: rgba(${rgb.red}, 0.2);
					}

					#custom-cpu {
						color: #${hex.fg};
					}

					#custom-cpu.normal {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-cpu.warning {
						color: #${hex.orange};
					}

					#custom-cpu.critical {
						color: #${hex.red};
						background: rgba(${rgb.red}, 0.2);
					}

					#custom-temperature {
						color: #${hex.fg};
					}

					#custom-temperature.normal {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-temperature.warning {
						color: #${hex.orange};
					}

					#custom-temperature.critical {
						color: #${hex.red};
						background: rgba(${rgb.red}, 0.2);
					}


					#pulseaudio {
						color: #${hex.fg};
					}

					#pulseaudio.muted {
						color: #${hex.gray};
					}

					#network {
						color: #${hex.fg};
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
						color: #${hex.fg};
					}

					#custom-notification {
						color: #${hex.fg};
					}

					#custom-devserver {
						color: #${hex.cyan};
					}

					#custom-devserver.inactive {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-focusmode {
						color: #${hex.cyan};
						font-weight: bold;
					}

					#custom-focusmode.active {
						background: rgba(${rgb.cyan}, 0.15);
						border: 1px solid rgba(${rgb.cyan}, 0.4);
						padding: 4px 10px;
						margin: 2px 4px;
					}

					#custom-focusmode.inactive {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-gamemode {
						color: #${hex.green};
						font-weight: bold;
					}

					#custom-gamemode.active {
						background: rgba(${rgb.green}, 0.15);
						border: 1px solid rgba(${rgb.green}, 0.4);
						padding: 4px 10px;
						margin: 2px 4px;
					}

					#custom-gamemode.inactive {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#custom-tmux {
						color: #${hex.text};
					}

					#custom-tmux.inactive {
						padding: 0;
						margin: 0;
						min-width: 0;
						border: none;
					}

					#tray {
						padding: 4px 8px;
						background: transparent;
						border: none;
						border-radius: 6px;
					}

					/* ── Group containers ── */
					#services,
					#hardware,
					#media-net,
					#status {
						background: rgba(${rgb.bg}, 0.85);
						border: none;
						border-radius: 8px;
						padding: 0 4px;
						margin: 4px 8px;
						transition: all 0.2s ease;
					}

					#services:hover,
					#hardware:hover,
					#media-net:hover,
					#status:hover {
						background: rgba(${rgb.bg}, 0.95);
					}

					#services {
						border-left: 3px solid rgba(${rgb.gray}, 0.5);
					}

					#hardware {
						border-left: 3px solid rgba(${rgb.gray}, 0.5);
					}

					#media-net {
						border-left: 3px solid rgba(${rgb.gray}, 0.5);
					}

					#status {
						border-left: 3px solid rgba(${rgb.gray}, 0.5);
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
