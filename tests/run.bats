#!/usr/bin/env bats

load helper

@test "cmd_run fails with no command specified" {
  run cmd_run
  [ "$status" -eq 1 ]
  [[ "$output" == *"no command specified"* ]]
}

@test "cmd_run fails when no .vlt.json exists" {
  cd "$TEST_DIR"
  run cmd_run -- echo hello
  [ "$status" -eq 1 ]
  [[ "$output" == *"no .vlt.json found"* ]]
}

@test "cmd_run fails when not authenticated" {
  local project_dir="$TEST_DIR/project"
  mkdir -p "$project_dir"
  create_project_config "$project_dir"
  cd "$project_dir"
  # No vault token
  unset VAULT_TOKEN
  rm -f "$HOME/.vault-token"
  run cmd_run -- echo hello
  [ "$status" -eq 1 ]
  [[ "$output" == *"not authenticated"* ]]
}

@test "cmd_run fails with invalid environment" {
  local project_dir="$TEST_DIR/project"
  mkdir -p "$project_dir"
  create_project_config "$project_dir"
  cd "$project_dir"
  # Create a fake vault token so we get past the auth check
  echo "fake-token" >"$HOME/.vault-token"
  run cmd_run -e nonexistent -- echo hello
  [ "$status" -eq 1 ]
  [[ "$output" == *"environment 'nonexistent' not found"* ]]
}
