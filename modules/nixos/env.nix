{ config, pkgs, ... }:

{
  environment.sessionVariables = {
    # NixOS-specific application paths
    ZSH = "$XDG_DATA_HOME/oh-my-zsh";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    GTK2_RC_FILES = "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";

    # Custom
    PROJECTS = "$HOME/Dev";
  };
}
