#!/usr/bin/env bash
# sudo-setup.sh — grant the_architect passwordless sudo
# Run ONCE manually: bash ~/dev/.dotfiles/scripts/sudo-setup.sh
# After this, sudo runs without prompts in this session and all future ones.

set -euo pipefail

SUDOERS_DROP="/etc/sudoers.d/the_architect"
RULE="the_architect ALL=(ALL:ALL) NOPASSWD: ALL"

# Validate rule syntax before writing (visudo -c)
echo "$RULE" | sudo visudo -cf - || {
    echo "ERROR: sudoers syntax check failed" >&2
    exit 1
}

# Write drop-in (440 permissions required)
echo "$RULE" | sudo tee "$SUDOERS_DROP" > /dev/null
sudo chmod 440 "$SUDOERS_DROP"

# Verify
sudo -n whoami >/dev/null 2>&1 && echo "✓ Passwordless sudo active" || echo "✗ Something went wrong"
echo "Drop-in: $SUDOERS_DROP"
