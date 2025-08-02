# .dotfiles

Cross-platform Nix configuration for NixOS and macOS using Nix flakes with enhanced productivity features.

## Features

- **Unified Configuration**: Both NixOS (Linux) and nix-darwin (macOS) support
- **Home-manager Integration**: Complete user environment management
- **Nixvim Configuration**: Neovim with LSP support and enhanced clipboard integration
- **Modular Architecture**: Shared cross-platform components with system-specific modules
- **Enhanced Terminal Experience**: Comprehensive shortcuts and utilities for maximum productivity
- **Smart Tmux Integration**: Mouse scrolling, battery indicator, and project-focused sessionizer
- **Seamless Clipboard Experience**: Universal system clipboard across terminal, tmux, and neovim
- **Development Workflow Optimizations**: Port management, quick file serving, and network diagnostics
- **Modern Audio Stack**: PipeWire with ALSA/JACK/PulseAudio compatibility (NixOS)
- **Gaming Support**: Steam with gamescope session support (NixOS)
- **Development Environment**: Docker, .NET, Node.js, Python with intelligent tooling
- **Tokyo Night Theme**: Consistent theming across all applications

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

### System Management Commands

```bash
# Core Nix commands (available everywhere)
nixswitch         # Apply configuration changes
nixup             # Update flake inputs and rebuild
nixtest           # Test configuration without building
nixclean          # Clean up old generations and optimize store
nixgen            # List system generations
nixvalidate       # Pre-flight checks before switching

# Enhanced Nix helpers
nixsearch firefox # Search packages with detailed info
nixinfo           # Show comprehensive Nix system status
```

### Development Environment Scripts

```bash
# Port management
checkport 3000    # Check what's running on port 3000
killport 3000     # Kill processes using port 3000

# Quick servers and utilities  
serve [port]      # Start HTTP server (default: 8000)
json [file]       # Pretty print JSON from stdin or file

# Project navigation
dev               # Jump to ~/Dev directory
dots              # Jump to ~/.dotfiles directory
```

### File Management Enhancements

```bash
# Quick navigation
..                # cd ..
...               # cd ../..
....              # cd ../../..
cdtemp            # Go to new temporary directory

# File operations
backup file.txt   # Create timestamped backup copy
```

### Enhanced Clipboard Integration

```bash
# Core clipboard utilities
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

### Network Utilities

```bash
# Network information
myip              # Get public IP address
localip           # Get local IP address
netinfo           # Comprehensive network information
speedtest         # Run internet speed test
```

### Tmux Session Management

```bash
# Enhanced tmux workflow
Ctrl+f            # Launch tmux sessionizer (fzf project selector)

# Dev projects automatically get multi-window setup:
# 🤖 AI      - Opens claude for AI assistance
# 📝 Editor  - Opens nvim in project directory  
# 🔨 Build   - For running builds/tests
# 💻 Terminal - General purpose terminal

# Tmux clipboard operations
Ctrl+a [          # Enter copy mode
v                 # Start visual selection (in copy mode)
y                 # Copy selection to system clipboard (in copy mode)
r                 # Rectangle selection toggle (in copy mode)
Ctrl+a p          # Paste from clipboard
Ctrl+a ]          # Alternative paste binding
```

### Neovim Clipboard Integration

```bash
# System clipboard is default - y and p work with system clipboard

# Enhanced clipboard keymaps (in neovim)
<leader>Y         # Copy entire file to system clipboard
<leader>P         # Paste from system clipboard before cursor
<leader>y         # Copy selection to system clipboard (visual mode)
<leader>cp        # Copy current file path to clipboard
<leader>p         # Paste but keep current clipboard (visual mode)
<leader>d         # Delete without affecting clipboard
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

- **Enhanced Zsh Configuration**: Custom shell with oh-my-posh prompt, comprehensive aliases, and productivity plugins
- **Smart Tmux Setup**: Terminal multiplexer with mouse scrolling, battery indicator, and project-focused sessionizer
- **Cross-platform Scripts**: All utilities work on both macOS and Linux with intelligent error handling
- **Consistent UX**: Unified command interface across all tools with PATH integration
- **Development Tools**: Git, Neovim (via nixvim), ripgrep, lazygit, gh (GitHub CLI) with enhanced workflows
- **Modern CLI Tools**: bat, lsd, fzf, fd, tree-sitter for enhanced terminal experience
- **Audio System**: PipeWire with ALSA/JACK/PulseAudio compatibility (NixOS)
- **Gaming**: Steam with gamescope session support (NixOS)
- **Docker**: Container development environment with port management utilities

## Common Workflows

### Setting up a New Development Project
```bash
dev                           # Navigate to Dev directory
mkdir my-new-project && cd my-new-project
git init
tmux-sessionizer .           # Create development session
# Automatically opens: AI, Editor, Build, Terminal windows
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
nixvalidate                  # Check for issues
nixtest                      # Test configuration
nixswitch                    # Apply changes
```

### File Operations
```bash
backup important-file.txt    # Create timestamped backup
copy config.json             # Copy file to clipboard
dev && paste new-config.json # Navigate and paste clipboard
copypath                     # Copy current directory path
```

### Seamless Clipboard Workflows
```bash
# Terminal to Neovim workflow
ccat config.json             # Copy file contents to clipboard
# Open neovim, press 'p' to paste

# Neovim to Terminal workflow  
# In neovim: select text, <leader>y to copy
# In terminal: Alt+v to paste or use 'paste > output.txt'

# Tmux copy-paste workflow
# Ctrl+a [ to enter copy mode, 'v' to select, 'y' to copy
# Automatically available in terminal and neovim

# Monitor clipboard activity
clipwatch                    # See all clipboard changes in real-time

# Debugging clipboard issues
cb                           # Show current clipboard contents and stats
clipclear                    # Clear clipboard if needed
```

### Network Diagnostics
```bash
netinfo                      # Overview of network status
myip && localip              # Get both IP addresses
speedtest                    # Check connection speed
```

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

**Scripts not found after nixswitch:**
- Scripts are installed to `~/Scripts` and added to PATH
- Restart your terminal or run `source ~/.config/zsh/.zshrc`

**Mouse scrolling not working in tmux:**
- Mouse support is enabled by default in the configuration
- Ensure you're using a compatible terminal emulator

**Battery indicator not showing:**
- macOS: Requires `pmset` (should be available by default)
- Linux: Requires `/sys/class/power_supply/BAT0` (most systems)
- Only shows when on battery power

**Clipboard operations failing:**
- macOS: Uses `pbcopy`/`pbpaste` (built-in)
- Linux: Requires `xclip` (X11) or `wl-copy` (Wayland) - install via system package manager
- Test clipboard: `echo "test" | clip && cb` should show "test"
- Check available tools: `which pbcopy xclip wl-copy`

**Clipboard not working between applications:**
- Neovim: Check `:checkhealth` for clipboard provider status
- Tmux: Ensure `set-clipboard on` is enabled (should be automatic)
- Terminal: Try `Alt+c` to verify clipboard shortcuts work
- Cross-check: Copy in one app, run `cb` to verify it's in system clipboard

**nixswitch fails:**
- Run `nixvalidate` first to check for common issues
- Check `nix flake check ~/.dotfiles` for detailed error messages
- Ensure you have proper permissions (sudo for NixOS)

### Getting Help
- Run `nixinfo` to see available commands and system status
- Use `--help` flag with most scripts for usage information
- Check script source in `~/Scripts/` for debugging
- Check `CLAUDE.md` for detailed architecture and command reference
