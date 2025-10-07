# Repository Guidelines

## Project Structure & Ownership
- `flake.nix` is the canonical entry; update shared variables under `vars` and expose new modules via `outputs`.
- `hosts/` defines machine targets (`macbook`, `nixos-desktop`, etc.). Add new hardware as `<name>/default.nix` and gate overrides there.
- `modules/` splits reusable logic: keep cross-platform pieces under `modules/shared/`, place OS-specific differences in `modules/darwin/` or `modules/nixos/`.
- `home/` wraps the user’s Home Manager profile. Introduce new user-facing modules in `modules/shared` and import them from `home/default.nix`.
- `configuration/`, `lib/`, `theme/`, and `nix/` gather host presets, helper functions, UI theming, and pinned upstream sources respectively.

## Build, Test, and Development Commands
- `nix develop` boots a shell with `nixpkgs-fmt`, `nil`, and default tooling. Use it before formatting or linting.
- `nix flake check` validates the flake graph; treat a clean run as table stakes for every PR.
- macOS apply: `nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .#<host>` (replace `switch` with `test` for dry runs).
- NixOS apply: `sudo nixos-rebuild switch --flake .#<host>` or `... test --flake .#<host>` when iterating.
- Helper scripts (`nixswitch`, `nixup`, `nixtest`) wrap the flows above; find quick references in `README.md`.

## Style & Naming Conventions
- Format all `.nix` files using `nixpkgs-fmt`; run `nixpkgs-fmt $(git ls-files '*.nix')` inside `nix develop` before committing.
- Prefer two-space indentation, one attribute per line, and grouping related options with blank separators.
- Keep identifiers lowercase, hyphenated (`shared-clipboard.nix`), and aligned with directory purpose. Place host overrides next to the host definition rather than duplicating shared logic.

## Testing & Validation
- Minimum gate: `nix flake check`. Extend `outputs.checks` when adding scripts or services that deserve CI coverage.
- For Home Manager tweaks, run `home-manager switch --flake .#${USER}` on the target machine to confirm activation.
- Before pushing OS-specific changes, run the relevant `*-rebuild test` or the `nixtest` helper to catch boot-time or activation errors early.

## Contribution Workflow
- Commit titles should be imperative and scoped (`modules: enable touch id auth`), wrapped at 72 characters.
- Squash exploratory commits; leave review-ready history that mirrors logical changes.
- Pull requests must list affected hosts, manual follow-up steps, and attach command output or screenshots if behaviour changes.
- Confirm `nix flake check` (and any host `test` builds) in the PR description and tag the maintainer responsible for the touched module tree.
- When updating dependencies, document whether `nix flake update` was run and call out noteworthy upstream diffs.
