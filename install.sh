#!/bin/bash
set -euo pipefail
INSTALL_DIR="$HOME/.local/bin"
COMPLETION_DIR="$HOME/.local/share/vlt/completions"
# Anything we install lands here, so make it usable for the rest of this script
export PATH="$INSTALL_DIR:$PATH"
WORKDIR=$(mktemp -d)
trap 'rm -rf -- "$WORKDIR"' EXIT
echo "Installing vlt..."
echo ""

have() { command -v "$1" &>/dev/null; }

asroot() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

sha256() {
	if have sha256sum; then
		sha256sum "$1" | awk '{print $1}'
	else
		shasum -a 256 "$1" | awk '{print $1}'
	fi
}

# Refuses to proceed on an empty expected hash — an unverifiable download is a failure
verify() {
	local file="$1" expected="$2" label="$3" actual
	actual=$(sha256 "$file")
	if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
		echo "Error: checksum verification failed for ${label}"
		echo "  expected: ${expected:-<none published>}"
		echo "  actual:   $actual"
		exit 1
	fi
}

case "$(uname -m)" in
x86_64 | amd64) ARCH="amd64" ;;
aarch64 | arm64) ARCH="arm64" ;;
*) ARCH="" ;;
esac

# envconsul ships as a zip; unzip is the one thing we may need a package manager for
ensure_unzip() {
	have unzip && return 0
	if [ "$(id -u)" -ne 0 ] && ! have sudo; then
		return 1
	fi
	echo "  Installing unzip..."
	if have apt-get; then
		asroot apt-get update -qq && asroot apt-get install -y -qq unzip
	elif have dnf; then
		asroot dnf install -y -q unzip
	elif have yum; then
		asroot yum install -y -q unzip
	elif have pacman; then
		asroot pacman -Sy --noconfirm unzip
	elif have apk; then
		asroot apk add --no-cache unzip
	elif have zypper; then
		asroot zypper --non-interactive install unzip
	else
		return 1
	fi
	have unzip
}

fetch_hashicorp() {
	local name="$1" url file sums_url expected
	url=$(curl -fsSL "https://api.releases.hashicorp.com/v1/releases/${name}/latest" |
		grep -o "\"url\":\"[^\"]*linux_${ARCH}\.zip\"" | cut -d'"' -f4 | head -1) || true
	if [ -z "$url" ]; then
		echo "Error: no linux/${ARCH} build published for ${name}"
		exit 1
	fi
	file="$WORKDIR/$(basename "$url")"
	curl -fsSL "$url" -o "$file"
	sums_url="${url%/*}/$(basename "$url" | sed "s/_linux_${ARCH}\.zip\$/_SHA256SUMS/")"
	expected=$(curl -fsSL "$sums_url" | grep " $(basename "$file")\$" | awk '{print $1}') || true
	verify "$file" "$expected" "$name"
	ensure_unzip || {
		echo "Error: unzip is required to install ${name}. Install it and re-run."
		exit 1
	}
	unzip -qo "$file" -d "$WORKDIR"
	install -m 0755 "$WORKDIR/$name" "$INSTALL_DIR/$name"
}

fetch_gh() {
	local tag ver tgz base file expected
	tag=$(curl -fsSL "https://api.github.com/repos/cli/cli/releases/latest" |
		grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 | head -1) || true
	if [ -z "$tag" ]; then
		echo "Error: could not resolve the latest gh release"
		exit 1
	fi
	ver="${tag#v}"
	tgz="gh_${ver}_linux_${ARCH}.tar.gz"
	base="https://github.com/cli/cli/releases/download/${tag}"
	file="$WORKDIR/$tgz"
	curl -fsSL "$base/$tgz" -o "$file"
	expected=$(curl -fsSL "$base/gh_${ver}_checksums.txt" | grep " ${tgz}\$" | awk '{print $1}') || true
	verify "$file" "$expected" "gh"
	tar -xzf "$file" -C "$WORKDIR"
	install -m 0755 "$WORKDIR/gh_${ver}_linux_${ARCH}/bin/gh" "$INSTALL_DIR/gh"
}

fetch_jq() {
	local base="https://github.com/jqlang/jq/releases/latest/download" expected
	curl -fsSL "$base/jq-linux-${ARCH}" -o "$WORKDIR/jq"
	expected=$(curl -fsSL "$base/sha256sum.txt" | grep " jq-linux-${ARCH}\$" | awk '{print $1}') || true
	verify "$WORKDIR/jq" "$expected" "jq"
	install -m 0755 "$WORKDIR/jq" "$INSTALL_DIR/jq"
}

echo "Checking dependencies..."
missing=()
for dep in envconsul jq gh; do
	if have "$dep"; then
		echo "  ${dep}: ✓"
	else
		missing+=("$dep")
	fi
done
if [ ${#missing[@]} -gt 0 ]; then
	if have brew; then
		echo "  Installing ${missing[*]} via Homebrew..."
		brew install "${missing[@]}"
	elif [ "$(uname -s)" = "Linux" ] && [ -n "$ARCH" ]; then
		echo "  Installing ${missing[*]} to ${INSTALL_DIR} from official releases..."
		mkdir -p "$INSTALL_DIR"
		for dep in "${missing[@]}"; do
			case "$dep" in
			envconsul) fetch_hashicorp "$dep" ;;
			gh) fetch_gh ;;
			jq) fetch_jq ;;
			esac
			echo "  ${dep}: ✓ installed"
		done
	else
		echo ""
		echo "⚠  Missing: ${missing[*]}"
		echo "   envconsul: https://github.com/hashicorp/envconsul/releases"
		echo "   jq:        https://jqlang.github.io/jq/download/"
		echo "   gh:        https://github.com/cli/cli#installation"
		echo "   vlt needs envconsul and jq to run; gh is only needed for 'vlt login --gh'."
		echo ""
	fi
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
	echo "Downloading vlt..."
	curl -fsSL "https://raw.githubusercontent.com/latticafi/vlt/main/bin/vlt" -o "$WORKDIR/vlt"
	# Verify checksum if checksums.txt is available in the latest release
	checksums_url=$(curl -fsSL "https://api.github.com/repos/latticafi/vlt/releases/latest" 2>/dev/null |
		jq -r '.assets[] | select(.name == "checksums.txt") | .browser_download_url // empty' 2>/dev/null)
	if [ -n "$checksums_url" ]; then
		curl -fsSL "$checksums_url" -o "$WORKDIR/checksums.txt"
		expected=$(grep ' vlt$' "$WORKDIR/checksums.txt" | awk '{print $1}')
		verify "$WORKDIR/vlt" "$expected" "vlt"
		echo "  Checksum verified ✓"
	fi
	cp "$WORKDIR/vlt" "$INSTALL_DIR/vlt"
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
