# .dotfiles

Cross-platform Nix configuration for NixOS and macOS using Nix flakes.

## Features

- Unified configuration for both NixOS (Linux) and nix-darwin (macOS)
- Home-manager integration for user environment management
- Nixvim configuration for Neovim with LSP support
- Modular architecture with shared cross-platform components
- Modern audio stack with PipeWire (NixOS)
- Gaming support with Steam and compatibility tools
- Development environment with Docker, .NET, Node.js, Python
- Tokyo Night themed terminal environment

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
nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .
```

**For NixOS:**
```bash
sudo nixos-rebuild switch --flake .
```

## Usage

### Common Commands

**macOS (Darwin):**
```bash
# Test configuration without applying (no root required)
nix build ~/.dotfiles#darwinConfigurations.Stefans-MacBook-Pro.system

# Check configuration validity (no root required)
darwin-rebuild check --flake ~/.dotfiles#Stefans-MacBook-Pro

# Apply configuration (requires root)
sudo darwin-rebuild switch --flake ~/.dotfiles#Stefans-MacBook-Pro

# Using aliases (available in shell):
nixbuild   # Test build configuration
nixcheck   # Check configuration validity
nixswitch  # Apply configuration (requires sudo)
nixup      # Update flake and rebuild
```

**NixOS:**
```bash
# Test configuration without applying
nix build ~/.dotfiles#nixosConfigurations.stefan.config.system.build.toplevel

# Check configuration validity
sudo nixos-rebuild dry-build --flake ~/.dotfiles#stefan

# Apply configuration
sudo nixos-rebuild switch --flake ~/.dotfiles#stefan

# Using aliases (available in shell):
nixbuild   # Test build configuration
nixcheck   # Check configuration validity
nixswitch  # Apply configuration (requires sudo)
nixup      # Update flake and rebuild
```

### Package Management

This configuration uses a hybrid approach:
- **Nix packages**: Core development tools and system utilities
- **Homebrew** (macOS only): GUI applications and proprietary software
- **Home-manager**: User environment and dotfiles management

## Architecture

### Directory Structure

```
.dotfiles/
├── flake.nix              # Main flake configuration
├── CLAUDE.md              # Claude Code assistant instructions
├── hosts/                 # Host-specific configurations
│   └── nixos-desktop/    # NixOS configuration
├── configuration/         # Legacy configuration (unused)
├── modules/              # Reusable modules
│   ├── shared/           # Cross-platform modules (git, zsh, tmux)
│   ├── darwin/           # macOS-specific modules
│   ├── nixos/            # NixOS-specific modules
│   ├── config/           # Configuration files (oh-my-posh, etc)
│   └── scripts/          # Shell scripts (tmux-sessionizer)
├── nix/                  # Home-manager configuration
└── theme/                # UI theming configuration
```

### Key Components

- **Zsh Configuration**: Custom shell with oh-my-posh prompt, aliases, and plugins
- **Tmux Setup**: Terminal multiplexer with Tokyo Night theme and custom keybindings
- **Development Tools**: Git, Neovim (via nixvim), ripgrep, lazygit, gh (GitHub CLI)
- **Modern CLI Tools**: bat, lsd, fzf, fd, tree-sitter for enhanced terminal experience
- **Audio System**: PipeWire with ALSA/JACK/PulseAudio compatibility (NixOS)
- **Gaming**: Steam with gamescope session support (NixOS)
- **Docker**: Container development environment

## Shell Features

### Available Aliases

- `ls` → `lsd` (modern ls replacement)
- `la` → `lsd -al` (list all files)
- `ll` → `lsd -l` (long format)
- `claude` → System claude binary (NixOS) or `/Users/stefan/.claude/local/claude` (macOS)
- `nixbuild` → Test build configuration
- `nixcheck` → Check configuration validity
- `nixswitch` → Apply configuration (requires sudo)
- `nixup` → Update flake and rebuild

### Oh-My-Posh Prompt

Features a custom two-line prompt with:
- Git status and repository information
- Current directory with smart truncation
- Language version detection (Node.js, Python, etc.)
- Clean, minimalist design with icons

### Tmux Integration

- Prefix: Default (`Ctrl-b`)
- Custom keybindings for window navigation
- Tmux sessionizer script bound to `Ctrl-f`

## Customization

### Adding New Packages

**System packages** (available to all users):
```nix
# In modules/shared/system.nix
environment.systemPackages = with pkgs; [
  your-package-here
];
```

**User packages** (home-manager):
```nix
# In modules/shared/zsh.nix or create new module
home.packages = with pkgs; [
  your-package-here
];
```

**macOS apps** (Homebrew):
```nix
# In hosts/macbook/default.nix
homebrew.casks = [
  "your-app-here"
];
```

### Modifying the Shell Prompt

Edit `/Users/stefan/.dotfiles/modules/config/ohmyposhv3-v2.json` to customize the oh-my-posh prompt appearance and segments.

## Troubleshooting

### Common Issues

1. **Build fails with platform-specific packages**:
   - Check if packages are available on your platform
   - Use `lib.mkIf pkgs.stdenv.isLinux` for Linux-only packages

2. **Permission denied during rebuild**:
   - Use `nixswitch` alias which includes `sudo`
   - Or run: `sudo darwin-rebuild switch --flake ~/.dotfiles#Stefans-MacBook-Pro`

3. **Flake inputs out of date**:
   - Run `nixup` to update and rebuild
   - Or manually: `nix flake update`

4. **Claude command not found**:
   - Ensure shell is reloaded after configuration changes
   - Check that aliases are properly loaded with `alias | grep claude`
   - The system provides `claude` binary directly on NixOS

### Getting Help

- Check `CLAUDE.md` for detailed architecture and command reference
- Review module files in `modules/` for configuration options
- Use `nixcheck` to validate configuration before applying
