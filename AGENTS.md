# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` is the canonical entry point—extend shared inputs under `vars` and expose new outputs through `outputs`.
- `hosts/<host>/default.nix` defines machine-specific overrides (e.g., `hosts/macbook`, `hosts/nixos-desktop`); keep OS-neutral logic in `modules/shared`.
- Cross-platform modules live in `modules/shared/`, with OS divergences in `modules/darwin/` or `modules/nixos/`. Import user-facing modules from `home/default.nix`.
- Helper logic and presets: `configuration/` (host bundles), `lib/` (functions), `theme/` (UI tokens), and `nix/` (pinned sources).

## Build, Test, and Development Commands
- `nix develop` — open the flake devshell with `nixpkgs-fmt`, `nil`, and diagnostics.
- `nix flake check` — validate the entire flake graph; treat a clean run as mandatory before PRs.
- macOS: `nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .#macbook` (`test` for dry-run).
- NixOS: `sudo nixos-rebuild switch --flake .#<host>` or `... test --flake .#<host>`.
- Shortcuts: `./nixswitch`, `./nixup`, `./nixtest` wrap the flows above—see `README.md` for flags.

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
