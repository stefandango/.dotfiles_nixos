#
#  Shell
#

{ pkgs, vars, ... }:

{

	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				oh-my-posh
			];
			file = {
				".config/oh-my-posh/ohmyposhv3-v2.json" = {
					text = ''
					{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "foreground": "#26C6DA",
          "properties": {
            "macos": "mac"
          },
          "style": "plain",
          "template": "{{ if .WSL }}WSL at {{ end }}{{.Icon}}",
          "type": "os"
        },
        {
          "foreground": "#26C6DA",
          "style": "plain",
          "template": " {{ .UserName }}: ",
          "type": "session"
        },
        {
          "foreground": "lightGreen",
          "properties": {
            "style": "folder"
          },
          "style": "plain",
          "template": "{{ .Path }} ",
          "type": "path"
        },
        {
          "properties": {
            "branch_icon": "",
            "fetch_stash_count": true
          },
          "style": "plain",
          "template": "<#ffffff>on</> {{ .HEAD }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} ",
          "type": "git"
        },
        {
          "foreground": "#906cff",
          "style": "powerline",
          "template": "[\ue235 {{ if .Error }}{{ .Error }}{{ else }}{{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }}{{ end }}] ",
          "type": "python"
        },
        {
          "foreground": "#7FD5EA",
          "style": "powerline",
          "template": "[\ue626 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}] ",
          "type": "go"
        },
        {
          "foreground": "#76b367",
          "style": "powerline",
          "template": "[\ue718 {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }}] ",
          "type": "node"
        },
        {
          "foreground": "#f44336",
          "style": "powerline",
          "template": "[\ue791{{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}] ",
          "type": "ruby"
        },
        {
          "foreground": "#ea2d2e",
          "style": "powerline",
          "template": "[\ue738 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}] ",
          "type": "java"
        },
        {
          "foreground": "#4063D8",
          "style": "powerline",
          "template": " \ue624 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "type": "julia"
        },
        {
          "foreground": "#FFD54F",
          "style": "plain",
          "template": "\u276f ",
          "type": "text"
        }
      ],
      "type": "prompt"
    }
  ],
  "version": 2
}

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
			histSize = 100000;

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
