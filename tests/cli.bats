#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  export HOME="$TEST_DIR/home"
  mkdir -p "$HOME/.config/vlt"
  VLT_BIN="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)/bin/vlt"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "vlt with no args shows help" {
  run "$VLT_BIN" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Vault secret injector"* ]]
  [[ "$output" == *"Commands:"* ]]
}

@test "vlt --help shows help" {
  run "$VLT_BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Commands:"* ]]
}

@test "vlt -h shows help" {
  run "$VLT_BIN" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Commands:"* ]]
}

@test "vlt version shows version string" {
  run "$VLT_BIN" version
  [ "$status" -eq 0 ]
  [[ "$output" == "vlt "* ]]
}

@test "vlt --version shows version string" {
  run "$VLT_BIN" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "vlt "* ]]
}

@test "vlt version reads from version file" {
  echo "v1.2.3" >"$HOME/.config/vlt/version"
  run "$VLT_BIN" version
  [ "$status" -eq 0 ]
  [ "$output" = "vlt v1.2.3" ]
}

@test "vlt unknown command fails" {
  run "$VLT_BIN" foobar
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command: foobar"* ]]
}

@test "help lists all commands" {
  run "$VLT_BIN" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"init"* ]]
  [[ "$output" == *"login"* ]]
  [[ "$output" == *"run"* ]]
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"update"* ]]
  [[ "$output" == *"starship"* ]]
}
