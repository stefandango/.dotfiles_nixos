# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` is the canonical entry point—extend shared values under `vars` and expose new outputs through `outputs`. Inputs include `nixpkgs` (unstable), `home-manager`, `nixvim`, `nix-darwin`, `zen-browser`, and `nix-claude-code`.
- `hosts/<host>/default.nix` defines machine-specific overrides (`hosts/macbook` for the Darwin host `Stefans-MacBook-Pro`, `hosts/nixos-desktop` for the NixOS host `stefan`); keep OS-neutral logic in `modules/shared`.
- Cross-platform home-manager modules live in `modules/shared/` (`git.nix`, `zsh.nix`, `kitty.nix`, `firefox.nix`, plus the system-level `system.nix`). OS-specific divergences sit in `modules/darwin/` or `modules/nixos/`. The single home-manager entry point is `home/default.nix`, imported by both host outputs.
- Ancillary trees: `modules/config/` (static dotfile assets), `modules/scripts/` (shell scripts surfaced to `~/Scripts` via `modules/nixos/scripts.nix`), `nix/` (standalone nix configs such as `nvim.nix`), and `theme/` (UI tokens + `themes/`).

## Build, Test, and Development Commands
- `nix develop` — open the flake devshell with `nixpkgs-fmt`, `nil`, and diagnostics.
- `nix flake check` — validate the entire flake graph; treat a clean run as mandatory before PRs.
- macOS: `nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .#Stefans-MacBook-Pro` (swap `switch` for `check`/`build` for a dry-run).
- NixOS: `sudo nixos-rebuild switch --flake .#stefan` (use `test` instead of `switch` for a non-persistent activation).
- Shortcuts installed to `~/Scripts`: `nixswitch`, `nixup`, `nixtest`, `nixvalidate`, `nixclean`, `nixgen`, `nixinfo`—see `README.md` for flags. These are on `PATH` after a successful rebuild; they are not checked-in at the repo root.

## Coding Style & Naming Conventions
- Format every `.nix` file with `nixpkgs-fmt` (run inside `nix develop`).
- Use two-space indentation, one attribute per line, and blank lines to group related options.
- Name modules and files in lowercase-hyphen (`shared-clipboard.nix`); keep host overrides beside their host definitions.

## Testing Guidelines
- Baseline: `nix flake check` must pass; extend `outputs.checks` for new validations.
- For Home Manager updates, run `home-manager switch --flake .#${USER}` on the target machine.
- Before shipping OS-specific changes, run `nix-darwin ... test` or `nixos-rebuild test` (or `./nixtest`) to catch activation regressions early.

## Commit & Pull Request Guidelines
- Commit titles are imperative and scoped (`modules: enable touch id auth`), wrapped at 72 characters; squash noisy exploration.
- PR descriptions must note affected hosts, manual follow-up steps, and confirm `nix flake check` (plus relevant `test` builds).
- When updating dependencies, document whether `nix flake update` ran and surface notable upstream diffs; tag maintainers responsible for touched modules.
