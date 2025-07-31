# .dotfiles

Cross-platform Nix configuration for NixOS and macOS using Nix flakes.

## Features

- Unified configuration for both NixOS (Linux) and nix-darwin (macOS)
- Home-manager integration for user environment management
- Nixvim configuration for Neovim
- Modular architecture with shared components

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
# Rebuild configuration
darwin-rebuild switch --flake ~/.dotfiles/.#

# Update and rebuild
pushd ~/.dotfiles; nix flake update; darwin-rebuild switch --flake ~/.dotfiles/.#; popd

# Using aliases (available in shell):
nixswitch  # Rebuild configuration
nixup      # Update flake and rebuild
```

**NixOS:**
```bash
# Rebuild configuration
sudo nixos-rebuild switch --flake ~/.dotfiles/.#

# Update flake inputs
nix flake update
```

### Package Management

This configuration uses a hybrid approach:
- **Nix packages**: Core development tools and system utilities
- **Homebrew** (macOS only): GUI applications and proprietary software
- **Home-manager**: User environment and dotfiles management
