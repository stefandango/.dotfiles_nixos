#!/bin/bash
# Show git diff with PI analysis
set -euo pipefail

cd /Users/stefan/.dotfiles

git diff | pi --print "Analyze this git diff and:
1. Explain what changes are being made
2. Check if they follow project conventions
3. Suggest improvements if needed
4. Verify the changes won't break nix flake check"