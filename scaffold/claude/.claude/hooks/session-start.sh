#!/usr/bin/env bash
# Session Start Hook (SessionStart event)
# Injects current git context, active plan, and session health into Claude.
# Non-blocking (always exits 0).

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"
CONFIG_DIR=".claude"

# Collect git context
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
COMMITS=$(git log --oneline -3 2>/dev/null || echo "No commits")
UNCOMMITTED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
UNPUSHED=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ' || echo "0")

echo "=== Session Context ==="
echo "Branch: $BRANCH"
echo "Recent commits:"
echo "$COMMITS"
echo "Uncommitted files: $UNCOMMITTED"
echo "Unpushed commits: $UNPUSHED"

# Check for last session notes
NOTES_FILE="$PROJECT_DIR/$CONFIG_DIR/session-notes.md"
if [ -f "$NOTES_FILE" ]; then
  SESSION_NOTES=$(head -30 "$NOTES_FILE" 2>/dev/null || echo "")
  if [ -n "$SESSION_NOTES" ]; then
    echo ""
    echo "Last session:"
    echo "$SESSION_NOTES"
  fi
fi

# Nag if CLAUDE.md is still a placeholder
CONTEXT_FILE="$PROJECT_DIR/CLAUDE.md"
if [ -f "$CONTEXT_FILE" ]; then
  if grep -q "project-setup" "$CONTEXT_FILE" 2>/dev/null; then
    echo ""
    echo "NOTE: CLAUDE.md is still a placeholder. Run /project-setup to generate full"
    echo "project context (architecture, stack, conventions, verification commands)."
  fi
fi

# Load most recent active plan if present
PLANS_DIR="$PROJECT_DIR/$CONFIG_DIR/plans"
if [ -d "$PLANS_DIR" ]; then
  RECENT_PLAN=$(find "$PLANS_DIR" -type f \( -name "*.md" -o -name "*.plan.md" \) \
    ! -name "README.md" 2>/dev/null \
    | sort -t_ -k1 -r 2>/dev/null \
    | head -1)
  if [ -n "$RECENT_PLAN" ]; then
    PLAN_NAME=$(basename "$RECENT_PLAN")
    echo ""
    echo "=== Active Plan: $PLAN_NAME ==="
    head -30 "$RECENT_PLAN" 2>/dev/null || true
  fi
fi

# Warn if last session used high context
TOKEN_LOG="$PROJECT_DIR/$CONFIG_DIR/token-usage.jsonl"
if [ -f "$TOKEN_LOG" ]; then
  LAST_LINE=$(tail -1 "$TOKEN_LOG" 2>/dev/null || echo "")
  if [ -n "$LAST_LINE" ]; then
    USED_PCT=$(echo "$LAST_LINE" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ctx = d.get('context_window', {})
    pct = ctx.get('used_pct')
    if pct and float(pct) > 70:
        print(f'{pct:.0f}')
except Exception:
    pass
" 2>/dev/null || echo "")
    if [ -n "$USED_PCT" ]; then
      echo ""
      echo "WARNING: Last session used ${USED_PCT}% of the context window."
      echo "Consider using /compact or delegating to subagents to stay within limits."
    fi
  fi
fi

exit 0
