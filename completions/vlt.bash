# bash completion for vlt
_vlt() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  commands="init login run status update starship version help"

  case "$prev" in
  vlt)
    mapfile -t COMPREPLY < <(compgen -W "$commands" -- "$cur")
    return
    ;;
  login)
    mapfile -t COMPREPLY < <(compgen -W "--gh --userpass --token" -- "$cur")
    return
    ;;
  run)
    mapfile -t COMPREPLY < <(compgen -W "-e --env -q --quiet --" -- "$cur")
    return
    ;;
  -e | --env)
    # Complete environment names from .vlt.json if it exists
    local config
    config=$(
      dir="$PWD"
      while [ "$dir" != "/" ]; do
        [ -f "$dir/.vlt.json" ] && echo "$dir/.vlt.json" && break
        dir=$(dirname "$dir")
      done
    )
    if [ -n "$config" ] && command -v jq &>/dev/null; then
      local envs
      envs=$(jq -r '.environments | keys[]' "$config" 2>/dev/null)
      mapfile -t COMPREPLY < <(compgen -W "$envs" -- "$cur")
    fi
    return
    ;;
  esac

  # If we're past --, complete with filesystem commands
  local i
  for ((i = 1; i < COMP_CWORD; i++)); do
    if [ "${COMP_WORDS[i]}" = "--" ]; then
      mapfile -t COMPREPLY < <(compgen -c -- "$cur")
      return
    fi
  done
}

complete -F _vlt vlt
