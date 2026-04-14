#!/bin/bash
set -euo pipefail
INSTALL_DIR="$HOME/.local/bin"
COMPLETION_DIR="$HOME/.local/share/vlt/completions"
echo "Installing vlt..."
echo ""

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
if ! command -v gh &>/dev/null; then
  echo "  Installing gh..."
  brew install gh
else
  echo "  gh: ✓"
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$COMPLETION_DIR"

echo ""
echo "Installing vlt to ${INSTALL_DIR}..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/bin/vlt" ]; then
  cp "$SCRIPT_DIR/bin/vlt" "$INSTALL_DIR/vlt"
elif [ -f "$SCRIPT_DIR/vlt" ]; then
  cp "$SCRIPT_DIR/vlt" "$INSTALL_DIR/vlt"
else
  tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  echo "Downloading vlt..."
  curl -fsSL "https://raw.githubusercontent.com/latticafi/vlt/main/bin/vlt" -o "$tmpdir/vlt"
  # Verify checksum if checksums.txt is available in the latest release
  checksums_url
  checksums_url=$(curl -fsSL "https://api.github.com/repos/latticafi/vlt/releases/latest" 2>/dev/null |
    jq -r '.assets[] | select(.name == "checksums.txt") | .browser_download_url // empty' 2>/dev/null)
  if [ -n "$checksums_url" ]; then
    curl -fsSL "$checksums_url" -o "$tmpdir/checksums.txt"
    expected actual
    expected=$(grep ' vlt$' "$tmpdir/checksums.txt" | awk '{print $1}')
    actual=$(shasum -a 256 "$tmpdir/vlt" | awk '{print $1}')
    if [ "$expected" != "$actual" ]; then
      echo "Error: checksum verification failed"
      echo "  expected: $expected"
      echo "  actual:   $actual"
      exit 1
    fi
    echo "  Checksum verified ✓"
  fi
  cp "$tmpdir/vlt" "$INSTALL_DIR/vlt"
fi
chmod +x "$INSTALL_DIR/vlt"

# Install completions
echo "Installing completions..."
if [ -f "$SCRIPT_DIR/completions/vlt.bash" ]; then
  cp "$SCRIPT_DIR/completions/vlt.bash" "$COMPLETION_DIR/vlt.bash"
  cp "$SCRIPT_DIR/completions/vlt.zsh" "$COMPLETION_DIR/vlt.zsh"
else
  curl -fsSL "https://raw.githubusercontent.com/latticafi/vlt/main/completions/vlt.bash" -o "$COMPLETION_DIR/vlt.bash" 2>/dev/null || true
  curl -fsSL "https://raw.githubusercontent.com/latticafi/vlt/main/completions/vlt.zsh" -o "$COMPLETION_DIR/vlt.zsh" 2>/dev/null || true
fi

mkdir -p "$HOME/.config/vlt"
latest=$(curl -fsSL "https://api.github.com/repos/latticafi/vlt/releases/latest" | jq -r '.tag_name // "dev"' 2>/dev/null) || latest="dev"
echo "$latest" >"$HOME/.config/vlt/version"

# Add to PATH and source completions if not already there
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
  fi
  # Add completion sourcing
  if ! grep -q 'vlt/completions' "$SHELL_RC" 2>/dev/null; then
    if [[ "$SHELL_RC" == *zshrc* ]]; then
      # shellcheck disable=SC2016
      {
        echo ''
        echo '# vlt completions'
        echo 'fpath=("$HOME/.local/share/vlt/completions" $fpath)'
        echo '[[ -f "$HOME/.local/share/vlt/completions/vlt.zsh" ]] && source "$HOME/.local/share/vlt/completions/vlt.zsh"'
      } >>"$SHELL_RC"
    else
      # shellcheck disable=SC2016
      {
        echo ''
        echo '# vlt completions'
        echo '[[ -f "$HOME/.local/share/vlt/completions/vlt.bash" ]] && source "$HOME/.local/share/vlt/completions/vlt.bash"'
      } >>"$SHELL_RC"
    fi
    echo "  Added tab completion to $(basename "$SHELL_RC")"
  fi
fi

echo ""
echo "Done! Installed vlt ${latest} to ~/.local/bin/vlt"
echo ""
if ! echo "$PATH" | grep -q '.local/bin'; then
  echo "⚠  ~/.local/bin is not in your PATH yet."
  echo "   Run: source ~/.zshrc (or open a new terminal)"
  echo ""
fi
echo "Quick start:"
echo "  vlt login              — authenticate to Vault"
echo "  cd your-project && vlt init  — set up a project"
echo "  vlt run -- <command>   — inject secrets and run"
