#compdef vlt

_vlt() {
  local -a commands
  commands=(
    'init:Create .vlt.json in current directory'
    'login:Authenticate to Vault'
    'run:Inject secrets and run a command'
    'status:Check auth and config'
    'update:Update vlt to the latest version'
    'starship:Add vlt status to starship prompt'
    'version:Show vlt version'
    'help:Show usage information'
  )

  _arguments -C \
    '1:command:->command' \
    '*::arg:->args'

  case "$state" in
  command)
    _describe -t commands 'vlt command' commands
    ;;
  args)
    case "${words[1]}" in
    login)
      _arguments \
        '--gh[Authenticate via GitHub]' \
        '--userpass[Authenticate via username/password]' \
        '--token[Authenticate via Vault token]'
      ;;
    run)
      _arguments \
        '-e[Environment]:environment:->envs' \
        '--env[Environment]:environment:->envs' \
        '-q[Suppress warnings]' \
        '--quiet[Suppress warnings]' \
        '--[End of flags]'
      if [ "$state" = envs ]; then
        local config
        config=$(
          dir="$PWD"
          while [ "$dir" != "/" ]; do
            [ -f "$dir/.vlt.json" ] && echo "$dir/.vlt.json" && break
            dir=$(dirname "$dir")
          done
        )
        if [ -n "$config" ] && command -v jq &>/dev/null; then
          local -a envs
          envs=(${(f)"$(jq -r '.environments | keys[]' "$config" 2>/dev/null)"})
          _describe -t envs 'environment' envs
        fi
      fi
      ;;
    esac
    ;;
  esac
}

_vlt "$@"
