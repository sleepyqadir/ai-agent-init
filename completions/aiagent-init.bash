#!/usr/bin/env bash
# Bash tab completion for aiagent-init
#
# Install (pick one):
#   1. Source in ~/.bashrc or ~/.bash_profile:
#        source ~/ai-agent-init/completions/aiagent-init.bash
#
#   2. Drop into system completions directory:
#        cp completions/aiagent-init.bash /etc/bash_completion.d/aiagent-init
#
#   3. On macOS with bash-completion:
#        cp completions/aiagent-init.bash "$(brew --prefix)/etc/bash_completion.d/aiagent-init"

_aiagent_init_complete() {
  local cur prev words cword
  _init_completion 2>/dev/null || {
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
  }

  local all_flags="--claude --cursor --both --update --dry-run --verify --help"

  # Determine which platform flags have already been used
  local platform_used=false
  for word in "${COMP_WORDS[@]}"; do
    case "$word" in
      --claude|--cursor|--both) platform_used=true ;;
    esac
  done

  case "$cur" in
    --*)
      local available_flags="$all_flags"
      if $platform_used; then
        # Remove platform flags from suggestions if one is already set
        available_flags="$(printf '%s\n' $all_flags | grep -v -E '^--(claude|cursor|both)$')"
      fi
      COMPREPLY=($(compgen -W "$available_flags" -- "$cur"))
      return 0
      ;;
    *)
      # Suggest directories for the target path
      COMPREPLY=($(compgen -d -- "$cur"))
      return 0
      ;;
  esac
}

complete -F _aiagent_init_complete aiagent-init
