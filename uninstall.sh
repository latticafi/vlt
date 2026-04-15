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
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  if [ -f "$rc" ]; then
    sed -i '' '/^# vlt$/d' "$rc" 2>/dev/null
    sed -i '' "/^export PATH=\"\\\$HOME\/\.local\/bin:\\\$PATH\"$/d" "$rc" 2>/dev/null
    sed -i '' '/^# vlt completions$/d' "$rc" 2>/dev/null
    sed -i '' '/vlt\/completions/d' "$rc" 2>/dev/null
  fi
done

# Remove starship integration
STARSHIP_CONFIG="$HOME/.config/starship.toml"
if [ -f "$STARSHIP_CONFIG" ]; then
  sed -i '' '/^\[custom\.vlt\]$/,/^shell = \["bash", "--nologin"\]$/d' "$STARSHIP_CONFIG" 2>/dev/null
fi

echo "Finished removing vlt"
