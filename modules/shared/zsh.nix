{ config, pkgs, vars, ... }:
let
color = import ../../theme/colors.nix;
in
{

	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				bat
				lsd
				oh-my-posh
				fzf
                ripgrep
                lazygit
                neovim-unwrapped
                fd
                tree-sitter
			];
			file = {

			"Scripts/tmux-sessionizer" = {
				source = ../scripts/tmux-sessionizer;
				recursive = true;
				executable = true;
			};


			".config/oh-my-posh/ohmyposhv3-v2.json" = 
			{
				source = ../config/ohmyposhv3-v2.json;
				recursive = true;
			};
      ".omnisharp/omnisharp.json" = {
        source = ../config/omnisharp.json;
        recursive = true;
      };
		};
	file = {
		".config/lsd/colors.yaml" = {
			source = ../config/lsdtheme.yaml;
			recursive = true;
		};
	};
	file = {
		".config/lsd/config.yaml" = {
			source = ../config/lsdconfig.yaml;
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
		autosuggestion.enable = true;
		enableCompletion = true;
		syntaxHighlighting.enable = true;
		history = {
			size = 1000;
			save = 1000;
			share = true;
			ignoreAllDups = true;

		};
		historySubstringSearch = {
			enable = true;
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
export PATH="$PATH:/home/stefan/.dotnet/tools:/Users/stefan/.dotnet/tools"

bindkey -s ^f '~/Scripts/tmux-sessionizer\n'

# Set github copilot alias
#eval "$(gh copilot alias -- zsh)"

eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/ohmyposhv3-v2.json)"
		'';
	};
};
};

programs =  {
zsh.enable = true;
tmux = {
	enable = true;
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
		set-option default-terminal "screen-256color"
		#set -g status-utf8 on
		#set -g utf8 on
		set-option -g focus-events on

			#run-shell ${pkgs.tmuxPlugins.onedark-theme}/share/tmux-plugins/onedark-theme/tmux-onedark-theme.tmux
			run-shell ${pkgs.tmuxPlugins.tokyo-night-tmux}/share/tmux-plugins/tokyo-night-tmux/tokyo-night.tmux
			run-shell ${pkgs.tmuxPlugins.better-mouse-mode}/share/tmux-plugins/better-mouse-mode/scroll_copy_mode.tmux


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

	users.users.${vars.user} = {
		shell = pkgs.zsh;
	};
}


