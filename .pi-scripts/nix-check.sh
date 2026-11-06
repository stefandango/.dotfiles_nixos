#!/bin/bash
# PI script to run nix flake check in the current directory
set -euo pipefail

echo "Running nix flake check..."
cd /Users/stefan/.dotfiles
nix flake check 2>&1 | tee /tmp/nix-flake-check.log

if [ $? -eq 0 ]; then
    echo "✅ nix flake check passed"
else
    echo "❌ nix flake check failed"
    exit 1
fi