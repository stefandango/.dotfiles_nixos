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
    # Inherit Kitty's ANSI palette so panes/chrome match the terminal exactly.
    name = "terminal"

    # Overlay the "Graphite" design tokens (theme/colors.nix) so herdr's
    # highlights and agent-status colors stay on-brand:
    #   accent = steel-blue, green = done, yellow = needs-attention, red = error.
    [theme.custom]
    accent = "#6f8fb3"
    green  = "#7d9a6b"
    yellow = "#c2a15c"
    red    = "#b56b6b"

    [ui]
    # Steel-blue accent for highlights, focused borders, and navigation UI.
    accent = "#6f8fb3"
    sidebar_width = 28
    pane_borders = true
    pane_gaps = true
    # Show the detected agent (e.g. claude) in a pane border when it's unnamed.
    show_agent_labels_on_pane_borders = true

    # In-app toast when a background agent changes state (done / needs input).
    [ui.toast]
    delivery = "herdr"

    [ui.toast.herdr]
    position = "bottom-right"
  '';
}
