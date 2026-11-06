#!/bin/bash
# Run nix flake check with PI assistance
set -euo pipefail

cd /Users/stefan/.dotfiles

echo "Running nix flake check with PI assistance..."
pi --print "Run 'nix flake check' and analyze the output. If there are errors, explain them and suggest fixes. If the check passes, confirm it." << EOF
$(nix flake check 2>&1)
EOF