# .dotfiles

Cross-platform Nix configuration for NixOS and macOS using Nix flakes, with a
Hyprland + DankMaterialShell desktop on Linux and a shared terminal workflow
(zsh, tmux, herdr, kitty) on both.

## Features

- **Unified Configuration**: One flake, two hosts — NixOS (`stefan`) and nix-darwin (`Stefans-MacBook-Pro`) — sharing a single home-manager entry point
- **Modular Architecture**: Cross-platform modules in `modules/shared`, OS-specific ones in `modules/nixos` and `modules/darwin`
- **Terminal Workflow**: zsh + oh-my-posh, tmux, and [herdr](https://github.com/ogulcancelik/herdr) (an agent multiplexer) with matching fzf project sessionizers (`Ctrl+f` / `Alt+f`)
- **Git Worktrees (`wt`)**: One worktree per feature under `~/Dev/.worktrees`, wired into both sessionizers, with PR / merge / cleanup on finish
- **Review-first diffs**: [hunk](https://github.com/modem-dev/hunk) as git's pager and difftool
- **Seamless Clipboard Experience**: Universal system clipboard across terminal, tmux, and Neovim
- **Development Workflow Optimizations**: Port management, quick file serving, project stats, and network diagnostics
- **Hyprland Desktop (NixOS)**: Wayland compositor configured in Lua, with DankMaterialShell (one Quickshell process for bar, notifications, launcher, OSD, lock screen, polkit and wallpaper), greetd/tuigreet login, and pyprland scratchpads
- **Wallpaper-derived theming**: matugen generates a Material 3 palette from the
  current wallpaper on `scheme-neutral`, and DankMaterialShell, kitty, tmux, GTK
  and Qt all follow it. Two deliberate exceptions: kitty's 16 ANSI colours stay a
  muted static ramp (matugen's own ramp is far too saturated for a terminal, and
  herdr inherits it), and Neovim keeps its own colourscheme in its own repo.
- **Push Notifications (ntfy)**: Receive-only [ntfy](https://ntfy.sh) subscriber on both platforms — native desktop notifications from a self-hosted server
- **Tailscale / Headscale**: `tailscaled` on NixOS (with the user as operator), the Tailscale app on macOS, and a `tailscale-up` helper for Headscale registration
- **Syncthing**: `~/Vault` synced to the home server, with all discovery/relay/STUN phone-home disabled
- **Local LLM (llama.cpp)**: Vulkan-accelerated `llama-server` as a NixOS service (Metal on macOS), driven by the `llama` / `llama-fetch` scripts
- **Modern Audio Stack**: PipeWire with ALSA/JACK/PulseAudio compatibility (NixOS)
- **Gaming Support (NixOS)**: Steam with gamescope session, GameMode, MangoHud, ananicy-cpp, plus wine-staging for the Anarchy Online multibox launcher
- **Development Environment**: Docker, .NET 8 SDK (omnisharp/netcoredbg), Node.js/pnpm, Go, Python, VS Code, Rider, Zed
- **Self-expiring workarounds**: every temporary pin or patch carries a `TEMP` marker and `nixworkarounds` reports when it can be deleted

## Installation

### Prerequisites

1. Install Nix with flakes support
2. For macOS: Install Homebrew (<https://brew.sh>)

### Setup

1. Clone the repository:
```bash
nix-shell -p git
git clone <repository_url> ~/.dotfiles
```

2. Navigate to the directory:
```bash
cd ~/.dotfiles
```

3. Apply configuration:

**For macOS (Darwin):**
```bash
nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .#Stefans-MacBook-Pro
```

**For NixOS:**
```bash
sudo nixos-rebuild switch --flake .#stefan
```

After the first switch the `nixswitch` / `nixup` helpers are on `PATH` and take
over from the raw commands above. Run them **as your user, not with sudo** —
they elevate only the activation step themselves and refuse to start as root.

### After the first switch

Some state is deliberately runtime-owned rather than Nix-owned, so a fresh
machine needs it once:

**Both platforms**

```bash
# Neovim config is a separate repo, not part of this flake
git clone git@github.com:stefandango/LazyVim-Config.git ~/.config/nvim

# Write ~/.config/ntfy/credentials — see "Push Notifications" below
```

**NixOS**

```bash
~/Scripts/dmsplugins sync      # restore DMS plugins from dms-plugins.lock.json
~/Scripts/tailscale-up         # register against the Headscale server (prompts for the URL once)
sudo nano /etc/samba/credentials   # CIFS credentials for the /mnt/piserver automount
~/Scripts/llama-fetch          # optional: ~18.6 GB model; services.llama-cpp enables itself once it exists
```

Then, in DankMaterialShell: **Settings → Theme & Colors → Apply GTK Colors**.
This copies `adw-gtk3` out of the read-only Nix store into
`~/.local/share/themes/` and splices matugen's palette into it — GTK apps stay
on the stock theme until it has run once. There is no CLI equivalent in `dms`
itself, but the underlying script can be called directly:

```bash
DMS_DIR=$(dirname $(readlink -f $(which dms)))/../share/quickshell/dms
bash "$DMS_DIR/scripts/gtk.sh" ~/.config apply false "$DMS_DIR"
bash "$DMS_DIR/scripts/gtk.sh" ~/.config patch false "$DMS_DIR"
```

After that, every wallpaper change re-patches GTK automatically.

## Usage

### System Management Commands

```bash
# Core Nix commands (available everywhere)
nixswitch         # Build with nom, then activate (snapshots DMS settings first on NixOS)
nixup             # Update flake inputs, report stale workarounds, then nixswitch
nixtest           # nix flake check ~/.dotfiles (evaluate without building)
nixbuild          # Build the system closure only (alias, no activation)
nixcheck          # Dry-build (NixOS) / darwin-rebuild check (macOS) (alias)
nixvalidate       # Pre-flight checks before switching (+ workaround report)
nixworkarounds    # List temporary pins/patches and which can now be deleted
nixclean          # Garbage-collect old generations and optimise the store
nixgen            # List system generations
nixhome           # Find and remove clutter in ~ (result symlinks, stale history files, .backup files)

# Enhanced Nix helpers
nixsearch firefox # Search packages with detailed info
nixinfo           # Show Nix version, generation, store size and available commands

# NixOS only
nixupdates        # How far behind nixpkgs we are, and what a rebuild would move
nixupdates --diff # ...with the full package diff (slow: dry-run evaluates the new inputs)
```

`nixup` calls out one input change by name: when `dank-material-shell` moves, it
prints the old → new settings-schema version and reminds you to run
`dmssettings diff` after your next login (see [DankMaterialShell](#dankmaterialshell-dms)).

### Temporary Pins, Patches and Overrides

Every temporary hack (a version pin, a local `fetchpatch`, a disabled test
suite, an overlay routing around a broken upstream) carries a `TEMP` marker so
`nixworkarounds` can tell you when it has outlived its reason:

```nix
# TEMP[ananicy-cpp-includes]: local copy of the nixpkgs include fix
# TEMP-CHECK: nix_pkg_has_patch x86_64-linux ananicy-cpp fix-cstring-include
ananicy-cpp = prev.ananicy-cpp.overrideAttrs (old: { ... });
```

`TEMP-CHECK` answers "can this go yet?" by exit status — **0 means obsolete**.
Helpers: `nix_pkg_has_patch`, `nix_pkg_cached`, `nix_input_missing`,
`recheck_after <date>` (documented in `modules/scripts/nixworkarounds`). Omit
`TEMP-CHECK` when nothing can be tested and the entry is listed for manual
review on every run. `nixup` runs the report *before* building, because an
overlay that appends a patch nixpkgs has since adopted fails the build with
"Reversed (or previously applied) patch" rather than going quietly obsolete.

### Development Environment Scripts

```bash
# Port management
checkport 3000    # Check what's running on port 3000
killport 3000     # Kill processes using port 3000

# Quick servers and utilities
serve [port]      # Start HTTP server (default: 8000)
json [file]       # Pretty print JSON from stdin or file
projstats [dir]   # Project overview: languages, git state, file counts (runs in every new sessionizer session)

# Project navigation
dev               # Jump to ~/Dev directory
dots              # Jump to ~/.dotfiles directory
nas               # Jump to /mnt/piserver (NixOS CIFS automount)
z / zi            # zoxide: jump to a learnt directory / pick one interactively
```

### Project Sessionizers (tmux and herdr)

Two sibling pickers share the same fzf project list (`~/Dev`, `~/.dotfiles`,
and every `wt` worktree):

```bash
Ctrl+f            # tmux-sessionizer: one tmux session per project
Alt+f  /  herd    # herdr-sessionizer: one herdr workspace per project
```

Projects under `~/Dev` get a three-way layout in either tool:

```
🖥 Terminal   - runs projstats
🍯 Editor     - nvim .
🤖 AI         - claude
```

Anything else (e.g. `~/.dotfiles`) gets a single plain session/workspace.
Sessions are named after the git remote, and worktrees as `<project>__<feature>`.

**tmux** (prefix `Ctrl+a`):

```bash
Ctrl+a f          # Open the sessionizer in a new window
Ctrl+a X          # tmux-quit: kill this session and hop back to the previous one
Ctrl+a C-p / C-n  # Previous / next window
Ctrl+a [          # Copy mode (vi keys): v select, r rectangle, y copy to system clipboard
Ctrl+a p / ]      # Paste
```

Mouse scrolling is on, the status bar shows a colour-coded battery indicator
when on battery power, and on Linux the colours come from matugen
(`~/.config/tmux/dank-colors.conf`, re-sourced on every wallpaper change).

**herdr** — the persistent server is started on demand by the sessionizer.
Its config (`modules/shared/herdr.nix`) sets the prefix to `Ctrl+a` to match
tmux, inherits kitty's palette (`theme = "terminal"`), and pins the four
semantic accents so "this agent errored" never changes hue with the wallpaper.
The file is a read-only home-manager symlink; apply changes to a running
session with `herdr server reload-config`. herdr is installed from its flake
on NixOS and from Homebrew on macOS (the upstream flake does not build on
darwin).

### Git Worktree Workflow (wt)

```bash
wt new auth-fix       # New worktree + branch off the default branch
wt new fix --carry    # ...and bring uncommitted changes from the main checkout
wt new x --from v2    # Base it on another ref
wt                    # Fuzzy-pick a worktree and open it (herdr or tmux)
wt list               # All worktrees with ahead-count and dirty state
wt done               # Finish: PR (gh) / push / merge locally / abandon, then clean up
wt rm                 # Remove a worktree (and optionally its branch)
```

Worktrees live under `~/Dev/.worktrees/<project>/<feature>` (`WT_ROOT`).
`wt done` also closes the matching herdr workspace / tmux session. Requires
git and fzf; uses gum for prompts and gh for PRs when present.

### Git and hunk

`git diff` / `git show` open in hunk's split review UI (`core.pager`), and
`git difftool` compares pairs in it. Merges use git's built-in `nvimdiff`
mergetool with `diff3` conflict markers, since hunk is read-only. `git pull`
rebases with autostash (so syncing the repo between machines leaves no merge
bubbles), while deliberate merges keep their merge commit (`merge.ff = false`),
which is what makes `wt done`'s local-merge option visible as one commit.

### File Management Enhancements

```bash
# Quick navigation
..                # cd ..
...               # cd ../..
....              # cd ../../..
cdtemp            # Go to new temporary directory

# File operations
backup file.txt   # Create timestamped backup copy
ls / ll / la      # lsd
```

### Enhanced Clipboard Integration

```bash
# Core clipboard utilities (detect pbcopy → xclip → wl-copy)
copy [file]       # Copy file contents or stdin to clipboard
paste [file]      # Paste clipboard to file or stdout
copypath [path]   # Copy directory path to clipboard

# Advanced clipboard management
cb / clipshow     # Show clipboard contents with detailed info
cbw / clipwatch   # Watch clipboard changes in real-time
cbc / clipclear   # Clear clipboard contents
cbcp / copypath   # Copy current directory path

# Quick clipboard operations
clip              # Pipe command: echo "text" | clip
cpwd              # Copy current directory path with confirmation
ccat file.txt     # Copy file contents to clipboard

# Keyboard shortcuts (terminal)
Alt+c             # Show clipboard contents
Alt+v             # Paste from clipboard
Alt+x             # Clear clipboard
```

On macOS the left Option key is mapped to Alt in kitty so the `Alt+…` bindings
reach zsh; the right Option still types special characters. On NixOS the
`clip` alias is `wl-copy` — the desktop is Wayland-only and `xclip` is not
installed.

### Network Utilities

```bash
# Network information
myip              # Get public IP address
localip           # Get local IP address
netinfo           # Comprehensive network information
speedtest         # Run internet speed test

# Tailscale (NixOS)
tailscale-up [authkey]   # Register with the Headscale server (URL cached in ~/.config/headscale-url)
```

`services.tailscale` sets `--operator=stefan`, so `tailscale up/down`, exit
nodes and DNS changes work without sudo. On macOS Tailscale is the Homebrew
cask `tailscale-app`.

### Push Notifications (ntfy)

Both machines are **receive-only** subscribers to a self-hosted [ntfy](https://ntfy.sh)
server, showing native desktop notifications when a topic is published to. There
is no native Mac App Store app or Homebrew cask for ntfy, so both platforms use
the `ntfy` CLI as the subscriber:

- **macOS**: `modules/darwin/ntfy.nix` runs a `launchd` user agent
  (`ntfy-subscribe`) that fires native notifications via `terminal-notifier`.
- **NixOS**: `modules/nixos/ntfy.nix` runs a `systemd --user` service
  (`ntfy-subscribe`) that pipes messages to `notify-send`, rendered by
  DankMaterialShell. It subscribes to `$NTFY_TOPIC` **and** a fixed `alerts`
  topic over one connection.

Credentials are **never** stored in the Nix store or committed to git. On **both**
platforms, create the same out-of-store credentials file once:

```bash
mkdir -p ~/.config/ntfy
cat > ~/.config/ntfy/credentials <<'EOF'
NTFY_USER=youruser
NTFY_PASSWORD=yourpassword
NTFY_SERVER=https://your-ntfy-server   # or Tailscale hostname/IP
NTFY_TOPIC=yourtopic
EOF
chmod 600 ~/.config/ntfy/credentials
```

Then apply the config and verify:

```bash
nixswitch
curl -u user:pass -d "hello" https://server/topic   # triggers a desktop notification

# NixOS — inspect the subscriber service
systemctl --user status ntfy-subscribe              # should be active (running)

# macOS — inspect the launchd agent
launchctl list | grep ntfy-subscribe
tail -f /tmp/ntfy-subscribe.err.log                 # debug auth/connection issues
```

> On macOS the first notification may require granting `terminal-notifier`
> permission to send notifications (System Settings → Notifications).

### Neovim

Neovim itself comes from Nix (`neovim-unwrapped` in `modules/shared/zsh.nix`),
but its configuration does not: `~/.config/nvim` is a separate LazyVim checkout,
[stefandango/LazyVim-Config](https://github.com/stefandango/LazyVim-Config),
with its own colourscheme (kanagawa) — deliberately not wallpaper-derived, since
syntax highlighting wants a palette designed for it. The system clipboard is
the default register (`unnamedplus`), so plain `y`/`p` go through
`wl-copy`/`pbcopy` and round-trip with tmux and the terminal.

`nix/nvim.nix` is an older nixvim configuration that is not imported by either
host (the `nixvim` flake input is declared but unused).

### Hyprland Desktop (NixOS)

Hyprland is configured in **Lua** (`modules/nixos/hyprland.nix` generates
`~/.config/hypr/hyprland.lua`). Login is greetd + tuigreet on a One-Dark-themed
console; the Hyprland autostart then launches DMS (`dms run`), pyprland,
nm-applet, openrazer-daemon and Insync.

| Keys | Action |
| --- | --- |
| `SUPER+Return` | kitty |
| `SUPER+D` / `SUPER+Space` | DMS launcher (full spotlight / slim bar) |
| `SUPER+Q`, then `Q` or `Return` | Close window (armed for 5 s, `Esc` cancels; a DMS toast shows the state) |
| `SUPER+F` / `SUPER+Shift+Space` | Fullscreen / toggle floating |
| `SUPER+P` / `SUPER+J` | Pseudotile / toggle split (dwindle) |
| `SUPER+R` | Window submap: `1-5`/`e` split-ratio presets, `s` toggle split, `r` rotate, arrows resize ±100 px (`Shift` ±400), `Esc` exit |
| `SUPER+C` / `SUPER+Shift+P` | Centre / pin floating window |
| `SUPER+G`, `SUPER+Tab` | Toggle window group (tabs), cycle within it (`Shift` reverses; `SUPER+Shift+G` locks) |
| `Alt+Tab` | Cycle windows |
| `SUPER+arrows` / `+Shift` | Focus / move window; `+Alt` targets the other monitor |
| `SUPER+1…0` / `+Shift` | Switch / move to workspace; `SUPER+scroll` cycles |
| `SUPER+S` / `SUPER+Shift+S` | Toggle / move to the `magic` special workspace |
| `SUPER+½` (key left of `1`) | Terminal scratchpad (pyprland) |
| `SUPER+B` / `SUPER+Shift+B` / `SUPER+A` | btop / lazydocker / pavucontrol scratchpads |
| `SUPER+E` / `SUPER+I` / `SUPER+Z` | Thunar scratchpad / imv image picker / pyprland zoom |
| `SUPER+Shift+F` | Focus mode: gaps scale with the tiled-window count (one window becomes a centred column) |
| `Print` | Area screenshot to `~/Pictures` and clipboard (grimblast) |
| `SUPER+L` / `SUPER+N` / `SUPER+Y` | Lock / notification centre / clipboard history |
| `SUPER+Alt+Space` / `SUPER+Shift+T` | Control centre / DMS settings |
| `SUPER+Shift+E` | Power menu |
| `SUPER+Shift+W` | Wallpaper carousel (a plugin — dead until `dmsplugins sync` has run) |
| `SUPER+U` | NixOS updates popout (only while the pill is on the bar, i.e. when behind) |
| `SUPER+Shift+plus` | DMS keybind reference, generated from the live binds |
| `SUPER+Shift+R` | Reload Hyprland config |

Steam games (`steam_app_*`) go to workspace 10 fullscreen, except their
launcher/splash windows, which float. Validate config edits without restarting:
`Hyprland --verify-config -c ~/.config/hypr/hyprland.lua 2>&1 | grep '^config ok$'`.

Scripts that poke Hyprland at runtime must go through `~/Scripts/hypr-compat.sh`:
under the Lua config `hyprctl keyword` is refused and `hyprctl dispatch` takes
Lua, not legacy strings.

#### DankMaterialShell (DMS)

DMS owns the bar, notifications, launcher, OSD, lock/idle (lock at 10 min,
screen off at 11), polkit agent and wallpaper. It is launched from Hyprland's
autostart rather than its systemd unit, because the unit binds
`graphical-session.target`, which this plain (non-UWSM) session never activates.

- **Settings** (`~/.config/DankMaterialShell/settings.json`) belong to DMS, not
  Nix. `modules/nixos/dms.nix` seeds a writable copy once and never touches a
  real file again — so the Settings UI actually saves. When the look settles,
  re-dump with `dms ipc call settings dump` and fold it back into the seed.
- **`dank-material-shell` is an unpinned input.** Every `nixup` can land a
  shell whose settings schema has moved; unknown keys are silently dropped at
  the next login. `nixswitch` therefore snapshots the file first:

  ```bash
  dmssettings diff            # what the new shell dropped, and why (upstream vs. back-at-default)
  dmssettings list / restore  # snapshots live in ~/.local/state/dms-settings-backups
  ```

- **Plugins** are git clones under `~/.config/DankMaterialShell/plugins`, pinned
  by `modules/config/dms-plugins.lock.json`:

  ```bash
  dmsplugins [sync]   # restore every plugin at its locked commit (prunes unknown ones)
  dmsplugins update   # move all to upstream HEAD and re-lock — commit the diff
  dmsplugins list
  ```

  Bar widgets from plugins: `systemMonitorPlus`, `amdGpuMonitor`,
  `claudeCodeUsage`, `dankRazer` (mouse battery — needs the Go helper
  `dmsplugins` builds), `ddcBrightness` (the LG only takes brightness over
  DDC/CI), plus `wallpaperCarousel`. The `nixosUpdates` widget is ours and
  ships declaratively via `/etc/xdg/quickshell/dms-plugins` from
  `modules/nixos/dms/plugins/`; it renders `nixupdates --json`.

#### Theming

`modules/nixos/matugen.nix` adds user templates that DMS renders alongside its
own on every wallpaper change: kitty surfaces (`~/.config/kitty/dank-theme.conf`)
and tmux (`~/.config/tmux/dank-colors.conf`). Template *inputs* are
home-manager symlinks; *outputs* must be real files, so never declare them.
GTK is DMS's job (`Apply GTK Colors`, see Installation), Qt follows GTK3, and
Hyprland's border gradient and oh-my-posh stay static on purpose (the prompt
config is full of Go templates that matugen's engine would eat).

### Gaming (NixOS)

Steam runs with the gamescope session, GameMode (`renice 10`, GPU
optimisations) and protontricks wrapped for its FHS env. MangoHud is configured
but **not** session-wide — add `mangohud %command%` to a game's launch options:

```
Shift_R+F12       # toggle HUD
Shift_R+F1        # cycle FPS cap 165 → 60 → uncapped
```

Anarchy Online (Project Rubi-Ka) runs outside Steam under raw wine-staging, one
prefix per multibox instance under `~/Games`:

```bash
ao-launch.sh setup      # create the prefixes
ao-launch.sh launcher   # PRK launcher (patching)
ao-launch.sh [1|2|3]    # launch all, or one, instance; `stop` kills them
```

Lutris and CoreCtrl were removed (Lutris's 32-bit FHS env dragged in a broken
i686 openldap; CoreCtrl's overdrive table triggered a Navi48 SMU lockup). GPU
monitoring is `amdgpu_top` / `nvtop`.

### Local LLM (llama.cpp)

```bash
llama-fetch       # download Qwen3-Coder-30B-A3B-Instruct Q4_K_M (~18.6 GB)
llama on|off      # start / stop the server (systemd on NixOS, nohup on macOS)
llama status      # running state, endpoint, loaded model
llama logs        # journalctl -u llama-cpp -f  /  tail the log file
```

The OpenAI-compatible endpoint is `http://127.0.0.1:8080/v1`. On NixOS
`services.llama-cpp` (Vulkan build, all layers on the GPU, 32k context) enables
itself only when the model file exists under `/var/lib/llama-cpp/models`, so
`nixswitch` once after the download. On macOS the `llama-cpp` package (Metal)
is launched by the script from `~/Models`.

### Package Management

This configuration uses a hybrid approach:
- **Nix packages**: Core development tools, CLI utilities, and on NixOS all GUI applications
- **Homebrew** (macOS only): GUI applications and casks (Firefox, Zen, Raycast, kitty, Fork, DBeaver, Discord, Tailscale, fonts…) plus the `uv` and `herdr` brews
- **Home-manager**: User environment and dotfiles management on both platforms

## Architecture

### Directory Structure

```
.dotfiles/
├── flake.nix                # Inputs and the two host outputs; devShell with nixpkgs-fmt + nil
├── CLAUDE.md                # Claude Code assistant instructions
├── AGENTS.md                # Contributor guidelines
├── .mcp.json                # mcp-nixos MCP server for Claude Code
├── hosts/
│   ├── macbook/             # Darwin host: system defaults, Homebrew, Touch ID, fonts
│   └── nixos-desktop/       # NixOS host: boot/plymouth, AMD GPU, PipeWire, Steam, polkit,
│                            #   CIFS mount, hardware-configuration.nix
├── home/default.nix         # Cross-platform home-manager entry (XDG paths, MangoHud, llama scripts)
├── modules/
│   ├── shared/              # git (+hunk), zsh + tmux + scripts, kitty, firefox (Linux only),
│   │                        #   syncthing, herdr, and the system-level system.nix
│   ├── darwin/              # ntfy launchd agent
│   ├── nixos/               # hyprland (Lua), dms, matugen, greetd, pyprland, apps, dotnet,
│   │   │                    #   env, llama-cpp, tailscale, ntfy, scripts
│   │   └── dms/plugins/     # nixosUpdates DMS plugin (shipped via /etc)
│   ├── config/              # oh-my-posh, lsd, omnisharp, matugen templates, dms-plugins.lock.json
│   └── scripts/             # Everything that lands in ~/Scripts
├── nix/nvim.nix             # Dormant nixvim config (not imported — see Neovim above)
└── theme/theming.nix        # GTK/Qt/cursor/font settings (colours come from matugen at runtime)
```

Scripts are surfaced to `~/Scripts` from three places: cross-platform ones in
`modules/shared/zsh.nix`, the `llama*` pair in `home/default.nix`, and the
NixOS-only desktop helpers in `modules/nixos/scripts.nix`.

### Key Components

- **Shell**: zsh with oh-my-posh (static palette tuned to match matugen's neutral scheme), oh-my-zsh plugins, zoxide, autosuggestions and syntax highlighting; XDG-clean `$HOME`
- **Multiplexers**: tmux and herdr, both on prefix `Ctrl+a`, both fed by the same project picker
- **Development Tools**: git + hunk, Neovim (LazyVim, separate repo), lazygit, gh, codex, ripgrep, fd, fzf, bat, lsd, tokei, tealdeer, gum
- **Desktop (NixOS)**: Hyprland (Lua) + DankMaterialShell + pyprland + greetd/tuigreet, matugen theming, Bibata cursors, Papirus icons for DMS's workspace pills, grayscale font AA for the WOLED panel
- **Browser**: Firefox managed declaratively on Linux only (policies, XDG profile path, `MOZ_LEGACY_PROFILES`); Homebrew Firefox/Zen on macOS
- **Audio System**: PipeWire with ALSA/JACK/PulseAudio compatibility (NixOS)
- **Gaming (NixOS)**: Steam + gamescope, GameMode, MangoHud, ananicy-cpp, wine-staging + winetricks
- **Docker**: `virtualisation.docker` plus docker-compose and lazydocker
- **Hardware (NixOS)**: AMD RX 9070 XT, LG 45" 5120x2160 WOLED capped at 120 Hz with a Dual Mode follower, DDC/CI via `ddcutil`, openrazer with battery notifier
- **Flake Inputs**: `nixpkgs` (unstable), `home-manager`, `darwin`, `dank-material-shell`, `herdr`, `hunk`, `zen-browser`, `nix-claude-code`, `mcp-nixos`, `nixvim` (declared, unused), and `nixpkgs-darwin-stable` (a `TEMP` pin that only hunk follows, until it stops claiming x86_64-darwin)

## Common Workflows

### Setting up a New Development Project
```bash
dev                           # Navigate to Dev directory
mkdir my-new-project && cd my-new-project
git init
tmux-sessionizer .           # or herdr-sessionizer . — Terminal / Editor / AI
```

### Working on a Feature in Parallel
```bash
wt new feature-x --carry     # worktree + branch, taking your uncommitted changes along
# ...work; Ctrl+f / Alt+f list it as <project>__feature_x
wt done                      # open a PR, push, or merge locally; worktree + session cleaned up
```

### Port Troubleshooting
```bash
checkport 3000               # See what's using port 3000
killport 3000                # Kill the process
serve 3000                   # Start new server on port 3000
```

### Configuration Management Workflow
```bash
dots                         # Go to dotfiles
# Make your changes...
nixvalidate                  # Check for issues (and stale TEMP workarounds)
nixtest                      # nix flake check
nixswitch                    # Apply changes (as your user — no sudo)
```

### Updating Everything
```bash
nixup                        # flake update → workaround report → build → switch
dmssettings diff             # after the next login, if nixup said DMS moved
dmsplugins update            # occasionally: bump DMS plugins and commit the lockfile
```

### File Operations
```bash
backup important-file.txt    # Create timestamped backup
copy config.json             # Copy file to clipboard
dev && paste new-config.json # Navigate and paste clipboard
copypath                     # Copy current directory path
```

### Network Diagnostics
```bash
netinfo                      # Overview of network status
myip && localip              # Get both IP addresses
speedtest                    # Check connection speed
```

## Customization

### Adding New Packages

**System packages** (both hosts):
```nix
# In modules/shared/system.nix
environment.systemPackages = with pkgs; [
  your-package-here
];
```

**User packages** (home-manager, both hosts):
```nix
# In home/default.nix or modules/shared/zsh.nix
home.packages = with pkgs; [
  your-package-here
];
```

**NixOS GUI apps**: `modules/nixos/apps.nix` (or the host's `systemPackages`
for hardware/gaming tools).

**macOS apps** (Homebrew):
```nix
# In hosts/macbook/default.nix
homebrew.casks = [
  "your-app-here"
];
```

### Adding a Script

Drop it in `modules/scripts/` and register it in `modules/shared/zsh.nix`
(cross-platform) or `modules/nixos/scripts.nix` (NixOS only); it lands in
`~/Scripts`, which is on `PATH`.

### Modifying the Shell Prompt

Edit `modules/config/ohmyposhv3-v2.json`. Its colours are static by design —
see the note in `modules/shared/zsh.nix` for why it is not a matugen template.

### Changing the Desktop Shell Look

Tune it in the DMS Settings UI (`SUPER+Shift+T`), then
`dms ipc call settings dump` and fold the result into `dmsSeedSettings` in
`modules/nixos/dms.nix` so a fresh machine starts there. Keys must exist in the
shell's current `SettingsSpec.js` — unknown ones are silently dropped.

## Troubleshooting

### Common Issues

**`nixswitch` refuses to run:**
- You ran it with `sudo`. Run it as your user; it elevates the activation step itself.

**Build fails with "Reversed (or previously applied) patch":**
- nixpkgs adopted a patch one of our `TEMP` overlays still applies. Re-read the
  `nixworkarounds` report `nixup` printed before the build and delete that block.

**Bootloader install fails with "No space left on device":**
- `/boot` is 511 MB and each generation costs ~84 MB there (the initrd carries
  amdgpu firmware). `configurationLimit = 4` is the ceiling, because
  install-grub copies the new generation in *before* pruning. If a switch has
  already died, delete unneeded kernel/initrd pairs from `/boot/kernels` by
  hand — keeping whatever `/run/booted-system` and `/run/current-system`
  point at — and switch again.

**Scripts not found after nixswitch:**
- Scripts are installed to `~/Scripts` and added to PATH
- Restart your terminal or run `source ~/.config/zsh/.zshrc`

**DMS settings changed after `nixup`:**
- The shell moved to a commit whose schema dropped keys. `dmssettings diff`
  names them; `dmssettings restore` puts the pre-rebuild snapshot back if you
  need to compare in the UI.

**Bar widgets missing / `SUPER+Shift+W` does nothing:**
- Plugin widgets render nothing until `dmsplugins sync` has restored them;
  `dankRazer` additionally needs the Go helper that `dmsplugins` builds.

**GTK apps not following the wallpaper:**
- Run **Settings → Theme & Colors → Apply GTK Colors** once (see Installation).
  Nothing in this repo may manage `gtk-3.0/gtk.css` — DMS's `gtk.sh` bails out
  on a home-manager symlink there.

**A user service doesn't start after login (NixOS):**
- Anything `WantedBy=graphical-session.target` silently never starts: the
  plain (non-UWSM) Hyprland session never activates that target. Bind it to
  `default.target` instead — `ntfy-subscribe` already is, and DMS is launched
  from Hyprland's autostart for the same reason.

**Mouse scrolling not working in tmux:**
- Mouse support is enabled by default in the configuration
- Ensure you're using a compatible terminal emulator

**Battery indicator not showing:**
- macOS: Requires `pmset` (should be available by default)
- Linux: Requires `/sys/class/power_supply/BAT0` (most systems)
- Only shows when on battery power

**Clipboard operations failing:**
- macOS: Uses `pbcopy`/`pbpaste` (built-in)
- NixOS: Uses `wl-copy`/`wl-paste` from `wl-clipboard` (Wayland); `xclip` is not installed
- Test clipboard: `echo "test" | clip && cb` should show "test"
- Check available tools: `which pbcopy xclip wl-copy`

**Clipboard not working between applications:**
- Neovim: Check `:checkhealth` for clipboard provider status
- Tmux: Ensure `set-clipboard on` is enabled (should be automatic)
- Terminal: Try `Alt+c` to verify clipboard shortcuts work
- Cross-check: Copy in one app, run `cb` to verify it's in system clipboard

**ntfy notifications not appearing:**
- Confirm `~/.config/ntfy/credentials` exists with valid values (both platforms)
- NixOS: check the subscriber with `systemctl --user status ntfy-subscribe` and
  tail logs via `journalctl --user -u ntfy-subscribe -f`
- macOS: check the agent with `launchctl list | grep ntfy-subscribe` and tail
  `/tmp/ntfy-subscribe.err.log`
- macOS: grant `terminal-notifier` notification permission in
  System Settings → Notifications

**Tailscale pref changes are "Access denied":**
- `tailscaled` only trusts root or the configured operator; `modules/nixos/tailscale.nix`
  sets `--operator=stefan` via `extraSetFlags`, so make sure that switch has been applied.

**Monitor black screen at boot (LG 45GX950A):**
- The monitor's own OSD must be on **DP 1.4**, not 2.1 — the UHBR link degrades
  on this cable until the panel stops answering EDID. Full write-up in the
  `kernelParams` comment in `hosts/nixos-desktop/default.nix`.

**nixswitch fails:**
- Run `nixvalidate` first to check for common issues
- Check `nix flake check ~/.dotfiles` for detailed error messages
- Ensure you have proper permissions (sudo for NixOS)

### Getting Help
- Run `nixinfo` to see available commands and system status
- Use `--help` flag with most scripts for usage information
- Check script source in `~/Scripts/` for debugging
- The `.nix` modules carry long-form notes on every non-obvious decision
  (why DMS owns its settings, the DP 2.1 incident, the polkit rules, …)
- Check `CLAUDE.md` for the architecture and command reference used by Claude Code
