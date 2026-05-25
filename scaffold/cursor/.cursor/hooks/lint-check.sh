#!/usr/bin/env bash
# Lint Check Hook (postToolUse: Write|Edit)
# Detects the project linter and reminds the agent to run it after file writes.
# Does NOT run the linter automatically (too slow for a per-write hook).
# Non-blocking: always exits 0.

set -euo pipefail

PROJECT_DIR="${CURSOR_WORKSPACE_PATH:-$(pwd)}"
cd "$PROJECT_DIR"

# Read the written file path from stdin (Cursor postToolUse JSON)
FILE_PATH=""
if [ -t 0 ]; then
  # No stdin in some invocations
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    p = d.get('tool_input', {}).get('file_path', '') or d.get('tool_response', {}).get('file_path', '')
    print(p)
except Exception:
    pass
" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only lint source files — skip config, markdown, lock files
EXT="${FILE_PATH##*.}"
case "$EXT" in
  js|jsx|ts|tsx|mjs|cjs|py|rb|go|rs|java|kt|swift|c|cpp|h)
    ;;
  *)
    exit 0
    ;;
esac

# Detect linter from common config markers
LINT_CMD=""
LINT_LABEL=""

if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.cjs" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.yaml" ] || [ -f ".eslintrc.yml" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
  case "$EXT" in
    js|jsx|ts|tsx|mjs|cjs)
      LINT_CMD="npx eslint \"$FILE_PATH\""
      LINT_LABEL="ESLint"
      ;;
  esac
fi

if [ -z "$LINT_CMD" ] && ([ -f "pyproject.toml" ] || [ -f ".flake8" ] || [ -f "setup.cfg" ]); then
  case "$EXT" in
    py)
      if grep -q "ruff" pyproject.toml 2>/dev/null; then
        LINT_CMD="ruff check \"$FILE_PATH\""
        LINT_LABEL="Ruff"
      elif command -v flake8 >/dev/null 2>&1; then
        LINT_CMD="flake8 \"$FILE_PATH\""
        LINT_LABEL="Flake8"
      fi
      ;;
  esac
fi

if [ -z "$LINT_CMD" ] && [ -f "Cargo.toml" ]; then
  case "$EXT" in
    rs)
      LINT_CMD="cargo clippy"
      LINT_LABEL="Clippy"
      ;;
  esac
fi

if [ -z "$LINT_CMD" ] && [ -f ".golangci.yml" ] || ([ "$EXT" = "go" ] && [ -f "go.mod" ]); then
  case "$EXT" in
    go)
      LINT_CMD="go vet ./..."
      LINT_LABEL="go vet"
      ;;
  esac
fi

if [ -n "$LINT_CMD" ]; then
  echo "Lint reminder ($LINT_LABEL): $LINT_CMD" >&2
fi

exit 0
