#!/bin/bash
# PI wrapper script to ensure proper execution

# Set proper environment variables
export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0

# Use the Nix-installed PI but with proper Node execution
if [ -x "/nix/store/b6nqk0bgzi3b7dcy9nr7q1a3klrwvi3b-pi-coding-agent-1.0.4/bin/.pi-wrapped" ]; then
    exec -a "pi" node /nix/store/b6nqk0bgzi3b7dcy9nr7q1a3klrwvi3b-pi-coding-agent-1.0.4/lib/node_modules/pi-monorepo/dist/cli.js "$@"
else
    echo "PI not found in Nix store. Please install PI first."
    exit 1
fi