#compdef aiagent-init
# Zsh tab completion for aiagent-init
#
# Install (pick one):
#   1. Drop into a directory on your $fpath:
#        cp completions/aiagent-init.zsh /usr/local/share/zsh/site-functions/_aiagent-init
#        exec zsh
#
#   2. Source directly in ~/.zshrc:
#        source ~/ai-agent-init/completions/aiagent-init.zsh
#        compdef _aiagent_init aiagent-init
#
#   3. Use the install.sh --completions flag (when supported):
#        aiagent-init install --completions

_aiagent_init() {
  local context state state_descr line
  typeset -A opt_args

  _arguments -C \
    '(--claude --cursor --both)--claude[Install Claude Code scaffold (.claude/)]' \
    '(--claude --cursor --both)--cursor[Install Cursor scaffold (.cursor/)]' \
    '(--claude --cursor --both)--both[Install both Claude and Cursor scaffolds]' \
    '--update[Update an existing installation]' \
    '--dry-run[Preview changes without modifying anything]' \
    '--verify[Validate an existing installation]' \
    '(-h --help)'{-h,--help}'[Show help]' \
    '::target directory:_files -/'
}

_aiagent_init "$@"
