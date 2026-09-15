# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a cross-platform Nix configuration repository supporting both NixOS (Linux) and nix-darwin (macOS) setups. It is a single flake with home-manager for the user environment. The Linux host runs a Hyprland (Lua-configured) + DankMaterialShell desktop with wallpaper-derived theming; both hosts share the terminal workflow (zsh, tmux, herdr, kitty, the `~/Scripts` helpers).

## Architecture

- **flake.nix**: Main entry point. Inputs: `nixpkgs` (unstable), `home-manager`, `darwin`, `dank-material-shell` (the desktop shell), `herdr` (agent multiplexer, NixOS only — macOS uses Homebrew), `hunk` (git diff viewer), `zen-browser`, `nix-claude-code`, `mcp-nixos`, `nixvim` (**declared but unused**, see `nix/`), and `nixpkgs-darwin-stable` (a `TEMP` pin that only `hunk` follows). Outputs: `nixosConfigurations.stefan`, `darwinConfigurations.Stefans-MacBook-Pro`, and a `devShells.default` with `nixpkgs-fmt` + `nil`
- **hosts/**: Host-specific system configurations
  - `macbook/`: Darwin host (`Stefans-MacBook-Pro`) — system defaults, Homebrew casks + brews (`uv`, `herdr`), Touch ID, fonts
  - `nixos-desktop/`: NixOS host (`stefan`) — boot/plymouth (GRUB `configurationLimit = 4`, `/boot` is 511 MB), AMD RX 9070 XT, PipeWire, Steam/GameMode, polkit rules, CIFS automount, plus `hardware-configuration.nix`. Its comments are the record of the hardware incidents (DP 2.1 black screen, Dual Mode, CoreCtrl removal)
- **home/**: Cross-platform home-manager entry point (`home/default.nix`) consumed by both host outputs — XDG paths, MangoHud config, the `llama`/`llama-fetch` scripts
- **modules/**: Reusable Nix modules organized by functionality
  - `shared/`: Cross-platform home-manager modules — `git.nix` (+ hunk as pager/difftool), `zsh.nix` (zsh, tmux, and registration of every cross-platform script), `kitty.nix`, `firefox.nix` (Linux only — Homebrew Firefox on macOS), `syncthing.nix`, `herdr.nix` — and the system-level `system.nix`
  - `darwin/`: `ntfy.nix` (launchd subscriber)
  - `nixos/`: Linux-specific modules — `hyprland.nix` (generates `~/.config/hypr/hyprland.lua`), `dms.nix` (DankMaterialShell: seed settings, plugin flags, the `nixosUpdates` plugin via `/etc`), `matugen.nix` (user colour templates for kitty/tmux), `greetd.nix` (tuigreet), `pyprland.nix` (scratchpads), `apps.nix` (GUI apps), `dotnet.nix`, `env.nix`, `llama-cpp.nix`, `tailscale.nix`, `ntfy.nix`, `scripts.nix` (NixOS-only script registration)
  - `nixos/dms/plugins/nixosUpdates/`: our own DMS bar widget (QML), shipped read-only from the store
  - `config/`: Static assets — `ohmyposhv3-v2.json`, `lsdconfig.yaml`, `lsdtheme.yaml`, `omnisharp.json`, `matugen/{kitty,tmux}.conf` templates, `dms-plugins.lock.json`
  - `scripts/`: Everything that lands in `~/Scripts`
- **nix/nvim.nix**: An old nixvim config that is **not imported by either host**. The live Neovim config is a separate LazyVim repo checked out at `~/.config/nvim` (`github:stefandango/LazyVim-Config`); Nix only installs `neovim-unwrapped`
- **theme/**: `theming.nix` — GTK/Qt/cursor/font settings. Colours are not defined anywhere in this repo; matugen derives them from the wallpaper at runtime
- **.mcp.json**: registers the `mcp-nixos` MCP server (built from the flake input) for Claude Code

### Where scripts get registered

A script in `modules/scripts/` only reaches `~/Scripts` if it is listed in one of:

| File | Scope |
| --- | --- |
| `modules/shared/zsh.nix` (`home.file."Scripts/…"`) | both hosts |
| `home/default.nix` | both hosts (`llama`, `llama-fetch`) |
| `modules/nixos/scripts.nix` | NixOS only (desktop helpers, `nixupdates`, `dmsplugins`, `dmssettings`) |

## Conventions and Traps

Things that are easy to get wrong here. Each has a longer explanation in a comment at the site named.

- **Run `nixswitch` / `nixup` as the user, never with sudo.** Both refuse to start as root and elevate only the activation step (`modules/scripts/nixswitch`).
- **DMS owns `~/.config/DankMaterialShell/settings.json`.** Never declare it via `programs.dank-material-shell.settings` — a store symlink makes the Settings UI silently unable to save. `modules/nixos/dms.nix` seeds a writable copy once (`dmsSeedSettings`) and never touches it again. Seed keys must exist in the shell's current `SettingsSpec.js` or they are dropped without warning; re-dump with `dms ipc call settings dump` after tuning. `dank-material-shell` is unpinned, so `nixswitch` snapshots the file first and `dmssettings diff` shows what a new shell dropped.
- **DMS plugins are runtime state.** `modules/config/dms-plugins.lock.json` pins them; `dmsplugins sync|update` is deliberately a script, not a `home.activation` step, so switching never needs the network. `dmsplugins sync` prunes anything not in the lockfile — which is why our own `nixosUpdates` plugin ships via `environment.etc."xdg/quickshell/dms-plugins/…"` instead.
- **matugen template outputs must be real files.** Inputs (`~/.config/matugen/config.toml`, `templates/*`) are home-manager symlinks; outputs (`kitty/dank-theme.conf`, `tmux/dank-colors.conf`) must never be declared, or matugen fails silently and you get no colours. The `[config]` section in `config.toml` must exist and stay empty.
- **Nothing may manage `gtk-3.0/gtk.css` or `gtk-4.0/gtk.css`** — DMS's `gtk.sh` writes both and bails on a home-manager symlink. No `gtk.extraCss`.
- **No package may ship a D-Bus activation file for `org.freedesktop.Notifications`.** Activation bypasses module imports; whichever daemon wins the name owns every notification. DMS is the daemon.
- **`graphical-session.target` never activates.** The session that actually runs is plain `start-hyprland`, not UWSM (despite `withUWSM = true`). User services must be `WantedBy = default.target` (see `modules/nixos/ntfy.nix`); DMS is started from Hyprland's autostart instead of its systemd unit for the same reason.
- **Hyprland is configured in Lua.** `hyprctl keyword` is refused and `hyprctl dispatch` takes Lua, not legacy strings — scripts go through `~/Scripts/hypr-compat.sh`. `code:NN` binds are silently swallowed; use keysyms. Validate edits with `Hyprland --verify-config -c <file> 2>&1 | grep -q '^config ok$'` (the exit code is always 1). Later window rules win; regex is RE2 (no lookahead).
- **Compositor-spawned processes look sessionless to polkit** (`subject.active`/`.local` are false), so anything needing `auth_admin` silently no-ops. `security.polkit.extraConfig` in the host gates reboot/poweroff on group membership instead.
- **Firefox is managed on Linux only** (`lib.mkIf (!isDarwin)`); on macOS it comes from Homebrew and home-manager's `profiles.ini` takeover breaks it.
- **Anything hardcoding the LG's i2c bus or DP connector will rot** — they moved on the 2026-09-07 port swap. Use `ddcutil detect`.
- **Kitty's ANSI ramp and oh-my-posh's palette are static on purpose** — do not route them through matugen (see the notes in `modules/shared/kitty.nix` and `modules/shared/zsh.nix`).

### Temporary Pins, Patches and Overrides

Every temporary hack (a version pin, a local `fetchpatch`, a disabled test suite,
an overlay routing around a broken upstream) **must** carry a `TEMP` marker so
`nixworkarounds` can tell you when it has outlived its reason:

```nix
# TEMP[ananicy-cpp-includes]: local copy of the nixpkgs include fix
# TEMP-CHECK: nix_pkg_has_patch x86_64-linux ananicy-cpp fix-cstring-include
ananicy-cpp = prev.ananicy-cpp.overrideAttrs (old: { ... });
```

`TEMP-CHECK` answers "can this go yet?" by exit status — **0 means obsolete**,
non-zero means still needed. Helpers available inside it (defined in
`modules/scripts/nixworkarounds`, which also documents them):

| Helper | Obsolete when |
| --- | --- |
| `nix_pkg_has_patch <system> <attr> <patch>` | upstream nixpkgs carries the fix itself |
| `nix_pkg_cached <system> <attr>` | hydra built it, so it builds for us (eval-only, works cross-platform) |
| `nix_input_missing <input> <pattern>` | a flake input dropped the offending code |
| `recheck_after <YYYY-MM-DD>` | nothing to probe — plain calendar nag |

Omit `TEMP-CHECK` only when nothing can be tested; the entry is then listed for
manual review on every run. `nixup` runs the report **before** the build, because
an overlay appending a patch nixpkgs has since adopted fails the build with
"Reversed (or previously applied) patch" rather than going quietly obsolete.
Current entries: `hunk-darwin-nixpkgs` (flake.nix), `mcp-nixos-fastmcp` (host).

## Common Commands

### System Management Commands
```bash
# Core Nix commands (available everywhere) — run as the user, not sudo
nixswitch         # nom build, then activate (snapshots DMS settings first on NixOS)
nixup             # Update flake inputs → workaround report → nixswitch; calls out DMS moves
nixtest           # nix flake check ~/.dotfiles
nixbuild          # Build the system closure only (alias)
nixcheck          # Dry-build / darwin-rebuild check (alias)
nixvalidate       # Pre-flight checks before switching (+ workaround report)
nixworkarounds    # List temporary pins/patches and which can now be deleted
nixclean          # Garbage-collect old generations and optimise the store
nixgen            # List system generations
nixhome           # Find and remove clutter in ~
nixsearch firefox # Search packages with detailed info
nixinfo           # Show comprehensive Nix system status

# NixOS only
nixupdates        # How far behind nixpkgs we are, and what a rebuild would move
nixupdates --json # What the DMS nixosUpdates widget renders
```

### Development Environment Scripts
```bash
checkport 3000    # Check what's running on port 3000
killport 3000     # Kill processes using port 3000
serve [port]      # Start HTTP server (default: 8000)
json [file]       # Pretty print JSON from stdin or file
projstats [dir]   # Project statistics (runs in every new sessionizer session)
dev / dots / nas  # cd ~/Dev, ~/.dotfiles, /mnt/piserver
```

### Project Sessionizers (tmux and herdr)
```bash
Ctrl+f            # tmux-sessionizer (fzf over ~/Dev, ~/.dotfiles, and wt worktrees)
Alt+f  /  herd    # herdr-sessionizer — same picker, one herdr workspace per project

# ~/Dev projects get three windows/tabs; everything else a single plain one:
# 🖥 Terminal (projstats)  🍯 Editor (nvim .)  🤖 AI (claude)
# Sessions are named from the git remote; worktrees as <project>__<feature>.
```

Both tools use prefix `Ctrl+a`. herdr's config (`modules/shared/herdr.nix`) is a
read-only symlink — apply changes with `herdr server reload-config`.

### Git Worktree Workflow (wt)
```bash
wt new auth-fix       # New worktree + branch off the default branch
wt new fix --carry    # ...and bring uncommitted changes from the main checkout
wt                    # Fuzzy-pick a worktree and open it (herdr/tmux)
wt list               # All worktrees with ahead-count and dirty state
wt done               # Finish: PR / push / merge locally / abandon, then cleanup
wt rm                 # Remove a worktree (and optionally its branch)
```

Worktrees live under `~/Dev/.worktrees/<project>/<feature>`; `wt done` closes
the matching workspace/session. `label_for()` in `wt` and
`generate_session_name()` in both sessionizers must stay in sync.

### DankMaterialShell (NixOS)
```bash
dmsplugins [sync|update|list]      # Sync plugins against modules/config/dms-plugins.lock.json
dmssettings snapshot|diff|list|restore   # Keep settings.json diffable across shell updates
dms ipc call settings dump         # Current settings, for folding back into dms.nix's seed
```

### Local LLM
```bash
llama-fetch            # Download the model (NixOS: /var/lib/llama-cpp/models; macOS: ~/Models)
llama on|off|toggle|status|logs    # Drive llama-server (systemd on NixOS, nohup on macOS)
```

### Clipboard, Network, Files
```bash
copy [file] / paste [file] / copypath [path]     # Scripts: pbcopy → xclip → wl-copy detection
cb / cbw / cbc / cbcp                            # clipshow / clipwatch / clipclear / copypath
clip                  # Pipe to clipboard (pbcopy on macOS, wl-copy on NixOS)
cpwd / ccat file      # Copy cwd / file contents, with confirmation
Alt+c / Alt+v / Alt+x # Show / paste / clear clipboard (terminal)

myip / localip / netinfo / speedtest
tailscale-up [authkey]   # Register with the Headscale server (NixOS)

.. / ... / ....       # cd up
cdtemp                # cd to a new temp dir
backup file.txt       # Timestamped backup copy
```

### Tmux
```bash
Ctrl+a f          # Sessionizer in a new window
Ctrl+a X          # tmux-quit: kill session, reattach to the previous one
Ctrl+a C-p / C-n  # Previous / next window
Ctrl+a [          # Copy mode (vi): v select, r rectangle, y copy to system clipboard
Ctrl+a p / ]      # Paste
```

Mouse on; battery indicator when on battery; on Linux colours come from
`~/.config/tmux/dank-colors.conf` (matugen), sourced last so it overrides the
static fallback palette in `zsh.nix`.

### Neovim
Config is the separate LazyVim repo at `~/.config/nvim`, colourscheme kanagawa
(deliberately not matugen-driven). `clipboard = unnamedplus`, so `y`/`p` use the
system clipboard. There are no repo-defined Neovim keymaps.

### Hyprland (NixOS)
Keybinds live in `modules/nixos/hyprland.nix` (`shellBinds` for the DMS IPC
calls, the rest under `KEYBINDINGS`); the README carries the table.
`SUPER+Shift+plus` shows DMS's generated keybind reference. Autostart:
`dms run`, openrazer-daemon, nm-applet, pypr, insync.

## Configuration Variables

Key variables defined in flake.nix:
- **user**: "stefan"
- **location**: "$HOME/.dotfiles"
- **terminal**: "kitty"
- **editor**: "nvim"

## System Configurations

The flake defines configurations for:
- **NixOS**: `stefan` (x86_64-linux) — built via `sudo nixos-rebuild switch --flake .#stefan`
- **Darwin**: `Stefans-MacBook-Pro` (aarch64-darwin) — built via `nix run nix-darwin -- switch --flake .#Stefans-MacBook-Pro`

Both configurations use home-manager as a system module (no standalone
`homeConfigurations` output) with `home.stateVersion = "23.11"`, sharing a
single entry point at `home/default.nix`. `enableNixpkgsReleaseCheck = false`
silences the expected home-manager-master vs nixos-unstable version skew.

## Package Management

- Nix: all CLI tooling on both hosts, and every GUI app on NixOS (`modules/nixos/apps.nix`, the host's `systemPackages`, `modules/nixos/hyprland.nix`)
- Homebrew (macOS only): casks for GUI apps and fonts, brews `uv` and `herdr` (the herdr flake does not build on darwin)
- Cross-platform user packages: `home/default.nix` and `modules/shared/zsh.nix`; system-level for both hosts: `modules/shared/system.nix`

## Runtime State Nix Does Not Own

A fresh machine needs these once (details in README → Installation):
`~/.config/nvim` (git clone), `~/.config/ntfy/credentials`, `dmsplugins sync`,
DMS **Apply GTK Colors**, `tailscale-up`, `/etc/samba/credentials`, and
optionally `llama-fetch`. `services.llama-cpp` enables itself only when the
model file exists, so a `nixswitch` follows the download.

## Common Workflows

### Configuration Management
```bash
dots                         # Go to dotfiles
# Make your changes...
nixvalidate                  # Check for issues + stale TEMP workarounds
nixtest                      # nix flake check
nixswitch                    # Apply changes (as your user)
```

### Updating Everything
```bash
nixup                        # flake update → workaround report → build → switch
dmssettings diff             # after the next login, if nixup said DMS moved
dmsplugins update            # occasionally; commit the lockfile diff
```

### Feature Branch in a Worktree
```bash
wt new feature-x --carry     # worktree + branch, carrying uncommitted changes
wt done                      # PR / push / merge; worktree and session cleaned up
```

## Troubleshooting

**`nixswitch` refuses to run:** you used sudo — run it as your user.

**"Reversed (or previously applied) patch":** nixpkgs adopted a patch a `TEMP`
overlay still applies; delete the block `nixworkarounds` named.

**Bootloader "No space left on device":** `/boot` is 511 MB, ~84 MB per
generation, and install-grub copies before it prunes. Remove unneeded
kernel/initrd pairs from `/boot/kernels` (keep what `/run/booted-system` and
`/run/current-system` point at), then switch again.

**DMS settings changed after `nixup`:** `dmssettings diff` names the dropped
keys and why; `dmssettings restore` brings the pre-rebuild snapshot back.

**Bar widget missing / `SUPER+Shift+W` dead:** plugin not restored —
`dmsplugins sync` (also builds `dankRazer`'s Go helper).

**GTK apps not themed:** DMS Settings → Theme & Colors → Apply GTK Colors, once.

**User service never starts after login:** it is `WantedBy=graphical-session.target`;
bind it to `default.target`.

**Scripts not found after nixswitch:** installed to `~/Scripts` (on PATH) —
restart the terminal or `source ~/.config/zsh/.zshrc`. If it is a new script,
check it is registered (see "Where scripts get registered").

**Clipboard:** macOS `pbcopy`/`pbpaste`; NixOS `wl-copy`/`wl-paste` (`xclip` is
not installed). `echo test | clip && cb` should show "test".

**ntfy silent:** `~/.config/ntfy/credentials` must exist on both hosts;
NixOS `systemctl --user status ntfy-subscribe`; macOS `launchctl list | grep ntfy`
and `/tmp/ntfy-subscribe.err.log`, plus notification permission for `terminal-notifier`.

**Tailscale "Access denied: checkprefs":** the `--operator=stefan` set-flag has
not been applied; `nixswitch`.

**Black screen at boot on the LG:** monitor OSD must be on DP 1.4 — see the
`kernelParams` comment in `hosts/nixos-desktop/default.nix`.

### Getting Help
- `nixinfo` for status and the command list; `--help` on most scripts
- The `.nix` modules carry long-form notes on every non-obvious decision — read the comment before changing a line that has one
- `README.md` is the user-facing reference; keep the two in sync when changing commands or structure
