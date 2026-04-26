{ config, pkgs, ... }:

{
  environment.sessionVariables = {
    # XDG Base Directory specification
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_CACHE_HOME = "$HOME/.cache";

    # NixOS-specific application paths
    ZSH = "$XDG_DATA_HOME/oh-my-zsh";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    GTK2_RC_FILES = "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";

    # Custom
    PROJECTS = "$HOME/Dev";

    # Firefox 67+ auto-spawns a fresh profile when the install path changes
    # (nix-store hash bumps on every Firefox update). Legacy mode disables
    # per-install profile tracking so profiles.ini stays stable.
    MOZ_LEGACY_PROFILES = "1";
  };
}
