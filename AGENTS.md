# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` is the canonical entry point—extend shared values under `vars` and expose new outputs through `outputs`. Inputs: `nixpkgs` (unstable), `home-manager`, `darwin`, `dank-material-shell`, `herdr`, `hunk`, `zen-browser`, `nix-claude-code`, `mcp-nixos`, `nixvim` (declared, unused), and `nixpkgs-darwin-stable` (a `TEMP` pin followed only by `hunk`).
- `hosts/<host>/default.nix` defines machine-specific overrides (`hosts/macbook` for the Darwin host `Stefans-MacBook-Pro`, `hosts/nixos-desktop` for the NixOS host `stefan`); keep OS-neutral logic in `modules/shared`.
- Cross-platform home-manager modules live in `modules/shared/` (`git.nix`, `zsh.nix`, `kitty.nix`, `firefox.nix` (Linux only), `syncthing.nix`, `herdr.nix`, plus the system-level `system.nix`). OS-specific divergences sit in `modules/darwin/` (`ntfy.nix`) or `modules/nixos/` (`hyprland.nix`, `dms.nix`, `matugen.nix`, `greetd.nix`, `pyprland.nix`, `apps.nix`, `dotnet.nix`, `env.nix`, `llama-cpp.nix`, `tailscale.nix`, `ntfy.nix`, `scripts.nix`). The single home-manager entry point is `home/default.nix`, imported by both host outputs.
- Ancillary trees: `modules/config/` (static dotfile assets, matugen templates, `dms-plugins.lock.json`), `modules/scripts/` (shell scripts surfaced to `~/Scripts` — register cross-platform ones in `modules/shared/zsh.nix`, NixOS-only ones in `modules/nixos/scripts.nix`), `modules/nixos/dms/plugins/` (our DMS widget), `theme/theming.nix` (GTK/Qt/cursor/fonts; colours come from matugen at runtime), and `nix/nvim.nix` (a nixvim config that is **not imported** — the live Neovim config is the separate `LazyVim-Config` repo at `~/.config/nvim`).

## Build, Test, and Development Commands
- `nix develop` — open the flake devshell with `nixpkgs-fmt` and `nil`.
- `nix flake check` — validate the entire flake graph (`nixtest` is the alias); treat a clean run as mandatory before committing.
- macOS: `nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .#Stefans-MacBook-Pro` (swap `switch` for `check`/`build` for a dry-run).
- NixOS: `sudo nixos-rebuild switch --flake .#stefan` (use `test` instead of `switch` for a non-persistent activation).
- Shortcuts installed to `~/Scripts` after a successful rebuild: `nixswitch`, `nixup`, `nixvalidate`, `nixworkarounds`, `nixclean`, `nixgen`, `nixinfo`, `nixhome`, and on NixOS `nixupdates`—see `README.md`. Run `nixswitch`/`nixup` as the user, not with sudo; they refuse to start as root. They are not checked in at the repo root.
- home-manager is applied as part of the system switch on both hosts; there is no standalone `homeConfigurations` output.

## Coding Style & Naming Conventions
- Format every `.nix` file with `nixpkgs-fmt` (run inside `nix develop`).
- Use two-space indentation, one attribute per line, and blank lines to group related options.
- Name modules and files in lowercase-hyphen (`shared-clipboard.nix`); keep host overrides beside their host definitions.
- Non-obvious decisions get an explanatory comment at the site (why, not what); the existing modules set the bar. Read the comment before changing a line that has one.
- Every temporary pin, patch, overlay or disabled test **must** carry a `# TEMP[id]:` line and, where testable, a `# TEMP-CHECK:` line — see `CLAUDE.md` → "Temporary Pins, Patches and Overrides". `nixworkarounds` reports which have gone obsolete.

## Runtime-Owned State (do not declare)
- `~/.config/DankMaterialShell/settings.json` and `plugin_settings.json` — seeded once by `modules/nixos/dms.nix`, then DMS's; a store symlink breaks its Settings UI.
- matugen template outputs (`~/.config/kitty/dank-theme.conf`, `~/.config/tmux/dank-colors.conf`) — must be real files or matugen fails silently.
- `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` — written by DMS's `gtk.sh`.
- DMS plugins under `~/.config/DankMaterialShell/plugins` — pinned by `modules/config/dms-plugins.lock.json`, restored by `dmsplugins sync`.

## Testing Guidelines
- Baseline: `nix flake check` must pass. There are no `outputs.checks` yet; add them there if a validation is worth automating.
- Before shipping OS-specific changes, run `nix-darwin ... check` or `nixos-rebuild test` (or `nixcheck` / `nixbuild`) to catch activation regressions early.
- Hyprland config edits: `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua 2>&1 | grep '^config ok$'` (exit code is always 1; the line is the signal).
- Scripts: run with `--help` (most support it) and exercise them from `~/Scripts`, which is what the rest of the config invokes.

## Commit & Pull Request Guidelines
- Commit titles are imperative and wrapped at 72 characters (`Drop the openldap test-suite overlay along with its reason`); squash noisy exploration.
- When a change adds or removes a command, script, module or flake input, update `README.md` and `CLAUDE.md` in the same commit.
- When updating dependencies, note whether `nix flake update` ran and whether `nixworkarounds` reported anything; a moved `dank-material-shell` input should be followed by `dmssettings diff` after the next login.
- PR descriptions (when used) must note affected hosts, manual follow-up steps, and confirm `nix flake check` plus the relevant `test`/`check` build.
