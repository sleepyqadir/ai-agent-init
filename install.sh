#!/usr/bin/env bash
# One-time install: registers the aiagent-init command in your shell.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIAS_LINE="alias aiagent-init=\"$SCRIPT_DIR/bootstrap.sh\""

add_alias() {
  local rc_file="$1"
  if [ -f "$rc_file" ]; then
    # Remove any old aiagent-init alias lines first, then append the correct one
    grep -v "alias aiagent-init=" "$rc_file" > "$rc_file.tmp" && mv "$rc_file.tmp" "$rc_file"
    echo "$ALIAS_LINE" >> "$rc_file"
    echo "  updated: $rc_file"
  fi
}

echo "Installing aiagent-init..."
echo ""

add_alias "$HOME/.zshrc"
add_alias "$HOME/.bashrc"
add_alias "$HOME/.bash_profile"

echo ""
echo "Done. Open a new terminal or run:"
echo ""
echo "  source ~/.zshrc   # if you use zsh"
echo "  source ~/.bashrc  # if you use bash"
echo ""
echo "Then use:"
echo "  aiagent-init --claude .    (Claude Code setup)"
echo "  aiagent-init --cursor .    (Cursor setup)"
