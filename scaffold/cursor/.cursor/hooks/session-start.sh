#!/usr/bin/env bash
# Session Start Hook (sessionStart event)
# Injects current git context into Cursor's session via stdout.
# Non-blocking (always exits 0).

set -euo pipefail

PROJECT_DIR="${CURSOR_WORKSPACE_PATH:-$(pwd)}"
cd "$PROJECT_DIR"

# Collect git context
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
COMMITS=$(git log --oneline -3 2>/dev/null || echo "No commits")
UNCOMMITTED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
UNPUSHED=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# Check for last session notes
SESSION_NOTES=""
NOTES_FILE="$PROJECT_DIR/.cursor/session-notes.md"
if [ -f "$NOTES_FILE" ]; then
  SESSION_NOTES=$(head -20 "$NOTES_FILE" 2>/dev/null || echo "")
fi

# Output context
echo "=== Session Context ==="
echo "Branch: $BRANCH"
echo "Recent commits:"
echo "$COMMITS"
echo "Uncommitted files: $UNCOMMITTED"
echo "Unpushed commits: $UNPUSHED"

if [ -n "$SESSION_NOTES" ]; then
  echo ""
  echo "Last session:"
  echo "$SESSION_NOTES"
fi

exit 0
