#!/bin/bash
# PI script to switch nix configuration
set -euo pipefail

HOSTNAME=$(hostname)

case "$HOSTNAME" in
    "Stefans-MacBook-Pro")
        echo "Switching macOS configuration..."
        nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .#Stefans-MacBook-Pro
        ;;
    "stefan")
        echo "Switching NixOS configuration..."
        sudo nixos-rebuild switch --flake .#stefan
        ;;
    *)
        echo "Unknown hostname: $HOSTNAME"
        echo "Available hosts: Stefans-MacBook-Pro (macOS), stefan (NixOS)"
        exit 1
        ;;
esac