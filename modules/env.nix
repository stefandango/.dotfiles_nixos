{ config, pkgs, ... }:

{
  environment.sessionVariables = {
	XDG_CONFIG_HOME = "$HOME/.config";
	XDG_DATA_HOME = "$HOME/.local/share";
	XDG_STATE_HOME= "$HOME/.local/state";
	XDG_CACHE_HOME = "$HOME/.cache";
	
	ZSH = "$XDG_DATA_HOME/.oh-my-zsh";
	
	#CUSTOM
	PROJECTS = "~/Dev";
  };
}
