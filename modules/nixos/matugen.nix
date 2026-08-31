{ config, lib, pkgs, vars, ... }:

# User matugen templates — the seam for apps DMS does not theme itself.
#
# `dms matugen queue` runs with --run-user-templates on by default: it reads
# ~/.config/matugen/config.toml, splices its [templates] section in after its
# own built-ins, and invokes matugen with --import-json-string for dank16. So a
# template here sees the full {{colors.*}} role set AND {{dank16.*}}, and is
# re-rendered on every wallpaper change alongside DMS's own.
#
# The hard constraint: matugen writes its outputs with create/truncate, under
# --continue-on-error. A home-manager symlink into /nix/store is read-only, so
# the write fails and you get NO error and NO colours. Therefore:
#
#   inputs  (config.toml, templates/*)  -> home-manager managed, read-only. Fine.
#   outputs (kitty/dank-theme.conf, ...) -> must be real files. NEVER declare them.
#
# Deliberately not templated here:
#   oh-my-posh — its config is dense with Go templates ({{ .HEAD }},
#     {{ if gt .Ahead 0 }}...), and matugen's engine (upon) parses {{ }} itself
#     and has no raw-block escape. Rendering the file through matugen would mean
#     deleting every segment template, i.e. the prompt. Its palette is retuned
#     statically to match scheme-neutral instead — see modules/config/ohmyposhv3-v2.json.
#   gtk — DMS's own template does more than render: scripts/gtk.sh copies
#     adw-gtk3 out of the store and splices colours into the theme's gtk.css.

let
  home = "/home/${vars.user}";
  templates = "${home}/.config/matugen/templates";
in
{
  home-manager.users.${vars.user} = {
    xdg.configFile = {
      "matugen/templates/kitty.conf".source = ../config/matugen/kitty.conf;
      "matugen/templates/tmux.conf".source = ../config/matugen/tmux.conf;

      # The [config] section must be present and must stay EMPTY. matugen's TOML
      # schema requires the field -- without it the merged config fails to parse
      # with "missing field `config`", and because DMS splices this file into its
      # own config, that breaks the shell's ENTIRE theme generation, not just the
      # two templates below. Empty means it sets nothing, so it cannot shadow
      # DMS's own [config] either.
      "matugen/config.toml".text = ''
        [config]

        [templates.dankkitty]
        input_path = '${templates}/kitty.conf'
        output_path = '${home}/.config/kitty/dank-theme.conf'

        [templates.danktmux]
        input_path = '${templates}/tmux.conf'
        output_path = '${home}/.config/tmux/dank-colors.conf'
        post_hook = 'tmux source-file ${home}/.config/tmux/dank-colors.conf 2>/dev/null || true'
      '';
    };
  };
}
