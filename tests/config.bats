#!/usr/bin/env bats

load helper

# read_json

@test "read_json reads a key from a json file" {
  echo '{"name": "test-app"}' >"$TEST_DIR/test.json"
  result=$(read_json "$TEST_DIR/test.json" '.name')
  [ "$result" = "test-app" ]
}

@test "read_json returns default when key is missing" {
  echo '{}' >"$TEST_DIR/test.json"
  result=$(read_json "$TEST_DIR/test.json" '.name' "fallback")
  [ "$result" = "fallback" ]
}

@test "read_json returns empty string when key is missing and no default" {
  echo '{}' >"$TEST_DIR/test.json"
  result=$(read_json "$TEST_DIR/test.json" '.name')
  [ "$result" = "" ]
}

@test "read_json reads nested keys" {
  echo '{"environments": {"dev": "secret/data/dev"}}' >"$TEST_DIR/test.json"
  result=$(read_json "$TEST_DIR/test.json" '.environments.dev')
  [ "$result" = "secret/data/dev" ]
}

# save_global / read_global

@test "save_global creates config file" {
  save_global "https://vault.example.com" "github" ""
  [ -f "$GLOBAL_CONFIG" ]
}

@test "read_global reads saved addr" {
  save_global "https://vault.example.com" "github" ""
  result=$(read_global '.addr')
  [ "$result" = "https://vault.example.com" ]
}

@test "read_global reads saved method" {
  save_global "https://vault.example.com" "userpass" "alice"
  result=$(read_global '.method')
  [ "$result" = "userpass" ]
}

@test "read_global reads saved username" {
  save_global "https://vault.example.com" "userpass" "alice"
  result=$(read_global '.username')
  [ "$result" = "alice" ]
}

@test "read_global returns empty when no config exists" {
  result=$(read_global '.addr')
  [ "$result" = "" ]
}

# find_config

@test "find_config finds .vlt.json in current directory" {
  local project_dir="$TEST_DIR/project"
  mkdir -p "$project_dir"
  create_project_config "$project_dir"
  cd "$project_dir"
  result=$(find_config)
  [ "$result" = "$project_dir/.vlt.json" ]
}

@test "find_config walks up to find .vlt.json" {
  local project_dir="$TEST_DIR/project"
  mkdir -p "$project_dir/src/components"
  create_project_config "$project_dir"
  cd "$project_dir/src/components"
  result=$(find_config)
  [ "$result" = "$project_dir/.vlt.json" ]
}

@test "find_config fails when no .vlt.json exists" {
  cd "$TEST_DIR"
  run find_config
  [ "$status" -ne 0 ]
}
