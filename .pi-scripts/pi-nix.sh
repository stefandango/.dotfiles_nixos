#!/bin/bash
# PI helper script for Nix development
set -euo pipefail

# Use project-specific PI configuration
cd /Users/stefan/.dotfiles

# Start PI with project-specific settings
pi --session-dir .pi-sessions "$@"