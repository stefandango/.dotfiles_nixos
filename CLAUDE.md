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

### System Management (macOS/Darwin)
```bash
# Switch to new configuration
darwin-rebuild switch --flake ~/.dotfiles/.#

# Update flake inputs and rebuild
pushd ~/.dotfiles; nix flake update; darwin-rebuild switch --flake ~/.dotfiles/.#; popd

# Using the predefined aliases (when in nix environment):
nixswitch    # Equivalent to darwin-rebuild switch --flake ~/.dotfiles/.#
nixup        # Update flake and rebuild
```

### System Management (NixOS)
```bash
# Rebuild NixOS configuration
sudo nixos-rebuild switch --flake ~/.dotfiles/.#

# Update flake inputs
nix flake update
```

### Development Commands
```bash
# Enter development shell with git (for initial setup)
nix-shell -p git

# Check flake syntax and evaluate
nix flake check

# Show flake info
nix flake show
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