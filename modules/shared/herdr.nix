{ ... }:

{
  # herdr (agent multiplexer) appearance + keybindings.
  #
  # This is a read-only symlink managed by home-manager, so herdr cannot
  # self-edit it. Apply changes to a running session with:
  #   herdr server reload-config
  # An existing ~/.config/herdr/config.toml is preserved as *.backup
  # (home-manager.backupFileExtension = "backup").
  xdg.configFile."herdr/config.toml".text = ''
    # Skip the first-run onboarding flow
    onboarding = false

    [keys]
    # Match the tmux prefix (Ctrl+a) instead of herdr's default Ctrl+b.
    # All other bindings keep their defaults (prefix + w/n/p/h-j-k-l/c/...).
    prefix = "ctrl+a"

    [theme]
    # Inherit Kitty's ANSI palette so herdr matches the terminal exactly.
    name = "terminal"

    [ui]
    pane_borders = true
    pane_gaps = true
  '';
}
