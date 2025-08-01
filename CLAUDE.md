# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a cross-platform Nix configuration repository supporting both NixOS (Linux) and nix-darwin (macOS) setups. The configuration uses Nix flakes with home-manager for user environment management and nixvim for Neovim configuration.

## Architecture

The repository is structured as a unified flake supporting multiple system configurations:

- **flake.nix**: Main entry point defining inputs (nixpkgs, home-manager, nixvim, nix-darwin) and outputs for both NixOS and Darwin configurations
- **configuration/**: System-specific configurations
  - `nixos/`: NixOS (Linux) configuration files
  - `darwin/`: nix-darwin (macOS) configuration files
- **modules/**: Reusable Nix modules organized by functionality
  - `shared/`: Cross-platform modules (git, kitty, zsh)
  - `nixos/`: Linux-specific modules
  - `darwin/`: macOS-specific modules
- **nix/**: Home-manager and application configurations
- **theme/**: Theming and color scheme definitions

## Common Commands

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

## Configuration Variables

Key variables defined in flake.nix:
- **user**: "stefan"
- **location**: "$HOME/.dotfiles" 
- **terminal**: "kitty"
- **editor**: "nvim"

## System Configurations

The flake defines configurations for:
- **NixOS**: `stefan` (x86_64-linux)
- **Darwin**: `Stefans-MacBook-Pro` (aarch64-darwin)

Both configurations use home-manager for user environment management with home.stateVersion = "23.11".

## Package Management

This setup uses both Nix packages and selective Homebrew packages:
- Core development tools managed via Nix (ripgrep, curl, btop, bat)
- GUI applications like editors, Docker, and proprietary software managed via Homebrew
- Some GUI applications (Kitty, Meld, Raycast) managed through Nix/Homebrew integration

## Productivity Features

### Smart Tmux Integration
- **Mouse scrolling enabled** in all tmux sessions
- **Battery indicator** in tmux status bar with color-coded charge levels
- **Project-focused sessionizer** - searches only ~/Dev and ~/.dotfiles
- **Development session templates** - automatic multi-window setup for Dev projects

### Enhanced Terminal Experience
- **Cross-platform scripts** - all utilities work on both macOS and Linux
- **Intelligent error handling** - scripts gracefully handle missing dependencies
- **Consistent UX** - unified command interface across all tools
- **PATH integration** - all scripts available globally via ~/Scripts directory

### Seamless Clipboard Experience
- **Universal system clipboard** - copy/paste works consistently across terminal, tmux, and neovim
- **Automatic detection** - intelligently uses pbcopy (macOS), xclip (X11), or wl-copy (Wayland)
- **Visual feedback** - clipboard operations show confirmation messages
- **Real-time monitoring** - watch clipboard changes with clipwatch
- **Smart keybindings** - Alt+c/v/x for quick clipboard operations in terminal
- **Cross-application flow** - seamlessly copy from terminal to neovim to system and back

### Development Workflow Optimizations
- **Port management** - easily check and kill processes on specific ports
- **Quick file serving** - instant HTTP server for any directory
- **JSON formatting** - built-in pretty printing with jq fallback
- **Clipboard integration** - seamless copy/paste operations across platforms
- **Network diagnostics** - comprehensive network information at your fingertips

### Nix Configuration Management
- **Pre-flight validation** - check configuration before applying changes
- **Enhanced search** - detailed package information with version details
- **System monitoring** - track generations, store size, and update status
- **Automated cleanup** - intelligent garbage collection and store optimization

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