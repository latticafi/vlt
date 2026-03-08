#!/bin/bash
set -euo pipefail

echo "Removing vlt..."
rm -f "$HOME/.local/bin/vlt"
echo "Done. (vault, envconsul, and jq were left installed)"
echo "You can remove the PATH line from your ~/.zshrc if you want."
