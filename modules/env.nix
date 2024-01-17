{ config, pkgs, ... }:

{
  environment.sessionVariables = {
#	XDG_CONFIG_HOME = "$HOME/.config";
#	XDG_DATA_HOME = "$HOME/.local/share";
#	XDG_STATE_HOME= "$HOME/.local/state";
#	XDG_CACHE_HOME = "$HOME/.cache";
	
	ZSH = "$XDG_DATA_HOME/.oh-my-zsh";
	ZDOTDIR = ".config/zsh";
	GTK2_RC_FILES=".config/gtk-2.0/gtkrc";	
	#CUSTOM
	PROJECTS = "~/Dev";
  };
}
