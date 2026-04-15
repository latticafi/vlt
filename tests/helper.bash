#!/bin/bash

VLT_BIN="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)/bin/vlt"

setup() {
  TEST_DIR=$(mktemp -d)
  export HOME="$TEST_DIR/home"
  mkdir -p "$HOME"
  export GLOBAL_CONFIG_DIR="$HOME/.config/vlt"

  # Source vlt functions without executing main
  # shellcheck source=../bin/vlt
  source "$VLT_BIN"
  # Disable errexit — bats `run` captures exit codes itself
  set +e
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Create a .vlt.json in a directory
create_project_config() {
  local dir="${1:-.}"
  cat >"$dir/.vlt.json" <<'EOF'
{
  "addr": "https://vault.example.com",
  "project": "test-project",
  "environments": {
    "dev": "secret/data/dev/test-project",
    "staging": "secret/data/staging/test-project",
    "prod": "secret/data/prod/test-project"
  },
  "default_env": "dev"
}
EOF
}
