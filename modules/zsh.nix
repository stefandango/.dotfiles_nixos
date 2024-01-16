#
#  Shell
#

{ config, pkgs, vars, ... }:
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

	programs = {
		zsh = {
			enable = true;
			dotDir = ".config/zsh";
			shellAliases = {
				ls = "lsd";
				la = "lsd -al";
				ll = "lsd -l";
			};
			enableAutosuggestions = true;
			enableCompletion = true;
     			syntaxHighlighting.enable = true;     
			history = {
				path = ".local/share/zsh/history";
				size = 1000;
			};
			oh-my-zsh = {
				enable = true;
				plugins = [
					"git"
					"sudo"
					"azure"
					"docker"
					"docker-compose"
					"colored-man-pages"
					"command-not-found"
					"history"
					"copypath"
				];
			};
			initExtra = ''
bindkey -s ^f '~/Scripts/tmux-sessionizer\n'
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/ohmyposhv3-v2.json)"
			'';
		};
	};
	};
	programs.zsh.enable = true;
	users.users.${vars.user} = {
		shell = pkgs.zsh;
	};
}


