#!/usr/bin/env bash
# One-time install: registers the aiagent-init command in your shell.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="$SCRIPT_DIR/bootstrap.sh"
ALIAS_LINE="alias aiagent-init=\"$BOOTSTRAP\""

# Verify bootstrap.sh is present before wiring the alias
if [ ! -f "$BOOTSTRAP" ]; then
  echo "Error: bootstrap.sh not found at $BOOTSTRAP" >&2
  echo "Is the aiagent-init repo intact?" >&2
  exit 1
fi

# add_alias <rc_file>
# Returns: 0=file found and handled, 1=file not found (skipped)
add_alias() {
  local rc_file="$1"
  [ -f "$rc_file" ] || return 1

  # Check if the alias is already present and identical
  if grep -qF "$ALIAS_LINE" "$rc_file" 2>/dev/null; then
    echo "  already installed: $rc_file"
    return 0
  fi

  # Check if a stale alias exists (same name, different path)
  if grep -qF "alias aiagent-init=" "$rc_file" 2>/dev/null; then
    # Remove old line(s) safely with grep -v; guard against grep exiting non-zero
    grep -v "alias aiagent-init=" "$rc_file" > "$rc_file.tmp" || true
    mv "$rc_file.tmp" "$rc_file"
    echo "$ALIAS_LINE" >> "$rc_file"
    echo "  updated (new path): $rc_file"
    return 0
  fi

  # Fresh install
  echo "$ALIAS_LINE" >> "$rc_file"
  echo "  installed: $rc_file"
  return 0
}

echo "Installing aiagent-init..."
echo ""

any_installed=false
detected_shell=""

# Detect user's primary shell to give a useful post-install message
case "$SHELL" in
  */zsh)   detected_shell="zsh" ;;
  */bash)  detected_shell="bash" ;;
  */fish)  detected_shell="fish" ;;
  *)       detected_shell="" ;;
esac

# Process rc files; track whether any file was found and handled
add_alias "$HOME/.zshrc"        && any_installed=true || true
add_alias "$HOME/.bashrc"       && any_installed=true || true
add_alias "$HOME/.bash_profile" && any_installed=true || true

# If none of the expected rc files exist, create the right one
if ! $any_installed && [ -z "$(ls "$HOME"/.zshrc "$HOME"/.bashrc "$HOME"/.bash_profile 2>/dev/null)" ]; then
  if [ "$detected_shell" = "zsh" ] || [ -z "$detected_shell" ]; then
    echo "$ALIAS_LINE" >> "$HOME/.zshrc"
    echo "  created and installed: $HOME/.zshrc"
    detected_shell="zsh"
  else
    echo "$ALIAS_LINE" >> "$HOME/.bash_profile"
    echo "  created and installed: $HOME/.bash_profile"
    detected_shell="bash"
  fi
  any_installed=true
fi

echo ""

if $any_installed; then
  echo "Done. Open a new terminal or run:"
  echo ""
  case "$detected_shell" in
    zsh)  echo "  source ~/.zshrc" ;;
    bash) echo "  source ~/.bashrc" ;;
    *)
      echo "  source ~/.zshrc   # if you use zsh"
      echo "  source ~/.bashrc  # if you use bash"
      ;;
  esac
echo ""
echo "Then use:"
echo "  aiagent-init --claude .    (Claude Code setup)"
echo "  aiagent-init --cursor .    (Cursor setup)"
echo "  aiagent-init --both .      (both platforms)"
echo ""
echo "Optional: enable tab completion:"
if [ "$detected_shell" = "zsh" ]; then
  echo "  source $SCRIPT_DIR/completions/aiagent-init.zsh"
elif [ "$detected_shell" = "bash" ]; then
  echo "  source $SCRIPT_DIR/completions/aiagent-init.bash"
else
  echo "  source $SCRIPT_DIR/completions/aiagent-init.zsh  # zsh"
  echo "  source $SCRIPT_DIR/completions/aiagent-init.bash # bash"
fi
else
  echo "Warning: No shell rc files found and nothing was installed." >&2
  echo "Manually add this line to your shell config:" >&2
  echo "" >&2
  echo "  $ALIAS_LINE" >&2
  exit 1
fi
