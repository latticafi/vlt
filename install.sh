#!/bin/bash
set -euo pipefail

echo "Installing vlt..."
echo ""

# Check for Homebrew
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew is required. Install it from https://brew.sh"
  exit 1
fi

# Install dependencies
echo "Checking dependencies..."

if ! command -v vault &>/dev/null; then
  echo "  Installing vault..."
  brew install vault
else
  echo "  vault: ✓"
fi

if ! command -v envconsul &>/dev/null; then
  echo "  Installing envconsul..."
  brew install envconsul
else
  echo "  envconsul: ✓"
fi

if ! command -v jq &>/dev/null; then
  echo "  Installing jq..."
  brew install jq
else
  echo "  jq: ✓"
fi

# Install vlt
echo ""
echo "Installing vlt to /usr/local/bin..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/vlt" ]; then
  # Running from cloned repo
  sudo cp "$SCRIPT_DIR/vlt" /usr/local/bin/vlt
else
  # Running via curl — download from GitHub
  sudo curl -fsSL "https://raw.githubusercontent.com/lattica/vlt/main/vlt" -o /usr/local/bin/vlt
fi

sudo chmod +x /usr/local/bin/vlt

echo ""
echo "Done! Installed vlt $(vlt --version 2>/dev/null || echo "")"
echo ""
echo "Get started:"
echo "  vlt login              — authenticate to Vault"
echo "  cd your-project && vlt init  — set up a project"
echo "  vlt run -- <command>   — inject secrets and run"
