#!/usr/bin/env bash
# Dependency Audit Hook (PostToolUse: Write, Edit)
# Runs when package manifests change. Reports vulnerabilities.
# Exit 2 on CRITICAL vulnerabilities (blocks). Exit 0 otherwise.

set -euo pipefail

# Read the hook input to get the file path
HOOK_INPUT=$(cat)
FILE_PATH=$(echo "$HOOK_INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

# Only run on dependency manifests
case "$FILE_PATH" in
  *package.json|*package-lock.json|*pnpm-lock.yaml|*yarn.lock|*requirements.txt|*pyproject.toml|*go.mod|*Cargo.toml|*Pipfile|*Pipfile.lock|*poetry.lock|*uv.lock)
    ;;
  *)
    exit 0
    ;;
esac

echo "Dependency audit triggered by change to: $FILE_PATH" >&2

# Detect JS package manager and run audit
if [ -f "package.json" ]; then
  AUDIT_CMD=""
  if [ -f "pnpm-lock.yaml" ] && command -v pnpm &>/dev/null; then
    AUDIT_CMD="pnpm audit --json"
  elif [ -f "yarn.lock" ] && command -v yarn &>/dev/null; then
    AUDIT_CMD="yarn npm audit --all --recursive --json"
  elif command -v npm &>/dev/null; then
    AUDIT_CMD="npm audit --json"
  fi

  if [ -n "$AUDIT_CMD" ]; then
    echo "Running $AUDIT_CMD..." >&2
    AUDIT_OUTPUT=$($AUDIT_CMD 2>/dev/null || true)
    CRITICAL=$(echo "$AUDIT_OUTPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    vulns = data.get('metadata', {}).get('vulnerabilities', {})
    print(vulns.get('critical', 0))
except:
    print(0)
" 2>/dev/null || echo "0")

    HIGH=$(echo "$AUDIT_OUTPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    vulns = data.get('metadata', {}).get('vulnerabilities', {})
    print(vulns.get('high', 0))
except:
    print(0)
" 2>/dev/null || echo "0")

    if [ "$CRITICAL" -gt 0 ] 2>/dev/null; then
      echo "CRITICAL: $CRITICAL critical vulnerabilities found. Fix before continuing." >&2
      exit 2
    fi

    if [ "$HIGH" -gt 0 ] 2>/dev/null; then
      echo "WARNING: $HIGH high-severity vulnerabilities found." >&2
    fi
  fi
fi

# Python pip
if [ -f "requirements.txt" ] || [ -f "Pipfile" ]; then
  if command -v pip-audit &>/dev/null; then
    echo "Running pip-audit..." >&2
    PIP_OUTPUT=$(pip-audit --output=json 2>/dev/null || true)
    PIP_CRITICAL=$(echo "$PIP_OUTPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    vulns = [v for dep in data.get('dependencies', []) for v in dep.get('vulns', [])]
    print(len(vulns))
except:
    print(0)
" 2>/dev/null || echo "0")

    if [ "$PIP_CRITICAL" -gt 0 ] 2>/dev/null; then
      echo "CRITICAL: $PIP_CRITICAL Python vulnerabilities found. Run 'pip-audit' for details. Fix before continuing." >&2
      exit 2
    fi
  fi
fi

exit 0
