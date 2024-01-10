#
#  Shell
#

{ pkgs, vars, ... }:
let
color = import ../theme/colors.nix;
in
{

	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				bat
				lsd
				oh-my-posh
				fzf
			];
			file = {
				".config/oh-my-posh/ohmyposhv3-v2.json" = with color.scheme.default; {
					text = ''
{
    "final_space": true,
    "console_title": true,
    "console_title_style": "folder",
    "blocks": [
        {
            "type": "prompt",
            "alignment": "left",
            "horizontal_offset": 0,
            "vertical_offset": 0,
            "segments": [
                {
                    "type": "path",
                    "style": "diamond",
                    "powerline_symbol": "",
                    "invert_powerline": false,
                    "foreground": "#${hex.fg}",
                    "background": "#${hex.bg}",
                    "leading_diamond": "",
                    "trailing_diamond": "",
                    "properties": {
                        "prefix": "  ",
                        "style": "folder"
                    }
                },
                {
                    "type": "git",
                    "style": "powerline",
                    "powerline_symbol": "",
                    "invert_powerline": false,
                    "foreground": "#${hex.black}",
                    "background": "#${hex.orange}",
                    "leading_diamond": "",
                    "trailing_diamond": "",
                    "properties": {
                        "display_status": true,
                        "display_stash_count": true,
                        "display_upstream_icon": true
                    }
                },
                {
                    "type": "dotnet",
                    "style": "powerline",
                    "powerline_symbol": "",
                    "invert_powerline": false,
                    "foreground": "#ffffff",
                    "background": "#6CA35E",
                    "leading_diamond": "",
                    "trailing_diamond": "",
                    "properties": {
                        "display_version": true,
                        "prefix": "  "
                    }
                },
                {
                    "type": "root",
                    "style": "powerline",
                    "powerline_symbol": "",
                    "invert_powerline": false,
                    "foreground": "#ffffff",
                    "background": "#ffff66",
                    "leading_diamond": "",
                    "trailing_diamond": "",
                    "properties": null
                },
                {
                    "type": "exit",
                    "style": "powerline",
                    "powerline_symbol": "",
                    "invert_powerline": false,
                    "foreground": "#${hex.fg}",
                    "background": "#${hex.active}",
                    "leading_diamond": "",
                    "trailing_diamond": "",
                    "properties": {
                        "always_enabled": true,
                        "color_background": true,
                        "display_exit_code": false,
                        "error_color": "#f1184c",
                        "prefix": " ",
			"template": " \ue23a "
                    }
                }
            ]
        }
    ]
}
				'';
				};
			};
		file = {
			".config/lsd/colors.yaml" = {
				source = ./config/lsdtheme.yaml;
				recursive = true;	
			};
		};
		file = {
			".config/lsd/config.yaml" = {
				source = ./config/lsdconfig.yaml;
				recursive = true;
			};
		};
		};
	};

	users.users.${vars.user} = {
		shell = pkgs.zsh;
	};

	programs = {
		zsh = {
			enable = true;
			autosuggestions.enable = true;
			syntaxHighlighting.enable = true;
			enableCompletion = true;
			histSize = 1000;
			histFile = "~/.local/share/zsh/history";
			
			shellAliases = {
				ls = "lsd";
				la = "lsd -al";
				ll = "lsd -l";
			};

			ohMyZsh = {                               # Plug-ins
				enable = true;
				plugins = [ "git" "azure" "docker" "docker-compose" "sudo" "colored-man-pages" "command-not-found" "history" "copypath" ];
			};
		
			shellInit = ''
				eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/ohmyposhv3-v2.json)"
			'';
		};
		tmux = {
			enable = true;
			terminal = "tmux-256color";
			  historyLimit = 50000;
			  plugins = with pkgs;
			  [
			  #{
				  #plugin = tmux-super-fingers;
				  #extraConfig = "set -g @super-fingers-key f";
			  #}
		          tmuxPlugins.onedark-theme
			  tmuxPlugins.better-mouse-mode
			  tmuxPlugins.yank
			  ];
			  extraConfig = ''
				  unbind C-b
				  set-option -g prefix C-a
				  # Default start tab is 1 instead of 0
				  set -g base-index 1
				  bind r source-file ~/.config/tmux/tmux.conf


				# vim-like pane switching
				  bind -r ^ last-window
				  bind -r k select-pane -U
				  bind -r j select-pane -D
				  bind -r h select-pane -L
				  bind -r l select-pane -R

				  # Allow use of mouse
				  set -g mouse on

				# Super useful when using "grouped sessions" and multi-monitor setup
				  setw -g aggressive-resize on
				  
				  
				# Increase tmux messages display duration from 750ms to 4s
				  set -g display-time 4000

				  set -s escape-time 0

				# Easier and faster switching between next/prev window
				  bind C-p previous-window
				  bind C-n next-window

				# Enable VIM kyes in copy mode
				  setw -g mode-keys vi

				  bind-key -r f run-shell "tmux neww ~/Scripts/tmux-sessionizer"
				  '';
		};
	};

}
