{ config, lib, pkgs, ... }:

let
  # The hook herdr runs on each event. writeShellApplication puts git and jq on
  # PATH -- the hook runs in herdr's environment, not a login shell -- and
  # shellchecks the script at build time. hunk is deliberately not here: the
  # hook only types "hunk ..." into the new tab, where the user's shell resolves
  # it, so the pane shows a command you could have typed yourself.
  reviewTab = pkgs.writeShellApplication {
    name = "herdr-review-tab";
    runtimeInputs = [ pkgs.git pkgs.jq ];
    text = builtins.readFile ../config/herdr-review-tab.sh;
  };

  reviewManifest = pkgs.writeText "herdr-review-plugin.toml" ''
    id = "local.review"
    name = "Review tab"
    version = "1.0.0"
    min_herdr_version = "0.7.0"
    description = "One hunk review tab per git workspace."
    platforms = ["linux", "macos"]

    [[events]]
    on = "workspace.created"
    command = ["${reviewTab}/bin/herdr-review-tab"]

    [[events]]
    on = "worktree.created"
    command = ["${reviewTab}/bin/herdr-review-tab"]

    [[events]]
    on = "worktree.opened"
    command = ["${reviewTab}/bin/herdr-review-tab"]
  '';

  reviewPluginDir = "${config.xdg.configHome}/herdr/local-plugins/review";
in
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

    # theme.name = "terminal" means herdr inherits kitty's palette, which is
    # matugen-derived for the surfaces and a static muted ramp for the ANSI
    # colours (see modules/nixos/matugen.nix). These four overlay the semantic
    # accents on top: accent = steel-blue, green = done, yellow =
    # needs-attention, red = error. Static on purpose -- "this agent errored"
    # should not change hue when the wallpaper does.
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

  # A local herdr plugin that gives every git workspace one "review" tab running
  # hunk (see modules/config/herdr-review-tab.sh for the hook itself).
  #
  # Installed as a REAL FILE, not an xdg.configFile symlink, and that is the
  # whole point: `herdr plugin link` resolves symlinks before it records the
  # plugin. Pointed at a home-manager symlink it writes
  #   manifest_path = /nix/store/...-hm_....toml
  #   plugin_root   = /nix/store
  # into ~/.config/herdr/plugins.json, which freezes the plugin at the store
  # path it had on the day you linked it -- every later rebuild is ignored,
  # restarting herdr does not help (the registry is on disk), and plugin_root
  # points at the store root. With a real file herdr records this stable path,
  # re-reads it on every access, and picks up each rebuild with no re-link.
  #
  # Linking is still a one-time manual step per machine, since herdr's plugin
  # registry is runtime state it owns (like the DMS plugins):
  #   herdr plugin link ~/.config/herdr/local-plugins/review
  #
  # herdr has no workspace.opened event (the vocabulary is workspace.created /
  # .focused and worktree.created / .opened), and it needs none: a restored
  # session brings its tabs back, so the hook's label check sees the existing
  # review tab and does nothing.
  home.activation.herdrReviewPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg reviewPluginDir}
    # rm first: the destination may still be the old store symlink, and install
    # would otherwise follow it into the read-only store. -D is GNU-only, hence
    # the separate mkdir above.
    run rm -f ${lib.escapeShellArg "${reviewPluginDir}/herdr-plugin.toml"}
    run install -m644 ${reviewManifest} ${lib.escapeShellArg "${reviewPluginDir}/herdr-plugin.toml"}
  '';
}
