#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"

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

# Create install directory
mkdir -p "$INSTALL_DIR"

# Install vlt
echo ""
echo "Installing vlt to ${INSTALL_DIR}..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/vlt" ]; then
  cp "$SCRIPT_DIR/vlt" "$INSTALL_DIR/vlt"
else
  curl -fsSL "https://raw.githubusercontent.com/lattica/vlt/main/vlt" -o "$INSTALL_DIR/vlt"
fi

chmod +x "$INSTALL_DIR/vlt"

# Add to PATH if not already there
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
  SHELL_RC="$HOME/.bash_profile"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q '.local/bin' "$SHELL_RC" 2>/dev/null; then
    # shellcheck disable=SC2016
    {
      echo ''
      echo '# vlt'
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >>"$SHELL_RC"
    echo "  Added ~/.local/bin to PATH in $(basename "$SHELL_RC")"
    echo "  Run: source $SHELL_RC (or open a new terminal)"
  fi
fi

echo ""
echo "Done! Run 'vlt help' to get started."
echo ""
echo "Quick start:"
echo "  vlt login              — authenticate to Vault"
echo "  cd your-project && vlt init  — set up a project"
echo "  vlt run -- <command>   — inject secrets and run"
