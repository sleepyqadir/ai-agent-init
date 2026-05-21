#!/usr/bin/env bash
# install.sh — works two ways:
#   1. Piped from curl (no local clone):
#      curl -fsSL https://raw.githubusercontent.com/sleepyqadir/ai-agent-init/master/install.sh | bash
#   2. Run locally from inside the repo:
#      ./install.sh

set -euo pipefail

REPO_URL="https://github.com/sleepyqadir/ai-agent-init.git"
INSTALL_DIR="$HOME/.aiagent-init"

# ── Detect mode ───────────────────────────────────────────────────────────────
# When piped from curl, $0 is "bash" and there is no BASH_SOURCE[0] pointing
# to a real file. We detect this by checking whether bootstrap.sh exists next
# to the script. If not, we're in curl-pipe mode and must clone the repo first.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/bootstrap.sh" ]; then
  # ── Curl-pipe mode: clone or update the repo ────────────────────────────────
  echo "Installing aiagent-init..."
  echo ""

  if ! command -v git > /dev/null 2>&1; then
    echo "Error: git is required but not found in PATH." >&2
    echo "Install git and try again." >&2
    exit 1
  fi

  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "  Found existing install at $INSTALL_DIR — pulling latest..."
    git -C "$INSTALL_DIR" pull --ff-only 2>&1 | sed 's/^/  /'
  else
    echo "  Cloning into $INSTALL_DIR..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" 2>&1 | sed 's/^/  /'
  fi

  SCRIPT_DIR="$INSTALL_DIR"
  echo ""
fi

BOOTSTRAP="$SCRIPT_DIR/bootstrap.sh"

# Verify bootstrap.sh is present before wiring the alias
if [ ! -f "$BOOTSTRAP" ]; then
  echo "Error: bootstrap.sh not found at $BOOTSTRAP" >&2
  echo "Is the aiagent-init repo intact?" >&2
  exit 1
fi

ALIAS_LINE="alias aiagent-init=\"$BOOTSTRAP\""

# ── Shell alias helpers ───────────────────────────────────────────────────────

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

echo "Wiring shell alias..."
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
