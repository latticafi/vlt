#!/bin/bash
set -euo pipefail

echo "Removing vlt..."

# Remove binary
rm -f "$HOME/.local/bin/vlt"

# Remove global config
rm -rf "$HOME/.config/vlt"

# Remove completions
rm -rf "$HOME/.local/share/vlt"

# Remove PATH line and completion lines from shell rc
# -i.bak (no space) is the one form both BSD and GNU sed accept
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
	if [ -f "$rc" ]; then
		sed -i.bak '/^# vlt$/d' "$rc" 2>/dev/null
		sed -i.bak "/^export PATH=\"\\\$HOME\/\.local\/bin:\\\$PATH\"$/d" "$rc" 2>/dev/null
		sed -i.bak '/^# vlt completions$/d' "$rc" 2>/dev/null
		sed -i.bak '/vlt\/completions/d' "$rc" 2>/dev/null
		rm -f "$rc.bak"
	fi
done

# Remove starship integration
STARSHIP_CONFIG="$HOME/.config/starship.toml"
if [ -f "$STARSHIP_CONFIG" ]; then
	sed -i.bak '/^\[custom\.vlt\]$/,/^shell = \["bash", "--nologin"\]$/d' "$STARSHIP_CONFIG" 2>/dev/null
	rm -f "$STARSHIP_CONFIG.bak"
fi

echo "Finished removing vlt"
