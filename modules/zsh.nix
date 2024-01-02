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
				text = ''
				'';
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
	};
}
