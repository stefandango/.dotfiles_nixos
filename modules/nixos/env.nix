{ config, pkgs, ... }:

{
  environment.sessionVariables = {
    # XDG Base Directory specification
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_CACHE_HOME = "$HOME/.cache";

    # Application-specific XDG paths
    ZSH = "$XDG_DATA_HOME/oh-my-zsh";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    GTK2_RC_FILES = "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";

    # Custom
    PROJECTS = "$HOME/Dev";
  };
}
