#!/usr/bin/env bash
# Dependency Audit Hook (postToolUse: Write)
# Runs when package manifests change. Reports vulnerabilities.
# Exit 2 on CRITICAL vulnerabilities (blocks). Exit 0 otherwise.

set -euo pipefail

PROJECT_DIR="${CURSOR_WORKSPACE_PATH:-$(pwd)}"
cd "$PROJECT_DIR"

# Read the hook input to get the file path
HOOK_INPUT=$(cat)
FILE_PATH=$(echo "$HOOK_INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
# Cursor postToolUse nests file_path in tool_input
print(d.get('tool_input', {}).get('file_path', '') or d.get('file_path', ''))
" 2>/dev/null || echo "")

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
    YARN_VERSION=$(yarn --version 2>/dev/null | cut -d. -f1 || echo "0")
    if [ "$YARN_VERSION" -ge 2 ] 2>/dev/null; then
      AUDIT_CMD="yarn npm audit --all --recursive --json"
    else
      AUDIT_CMD="yarn audit --json"
    fi
  elif command -v npm &>/dev/null; then
    AUDIT_CMD="npm audit --json"
  fi

  if [ -n "$AUDIT_CMD" ]; then
    echo "Running $AUDIT_CMD..." >&2
    AUDIT_OUTPUT=$($AUDIT_CMD 2>/dev/null || true)

    if echo "$AUDIT_CMD" | grep -q "^yarn audit"; then
      CRITICAL=$(echo "$AUDIT_OUTPUT" | python3 -c "
import json, sys
critical = 0
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        if obj.get('type') == 'auditSummary':
            critical = obj.get('data', {}).get('vulnerabilities', {}).get('critical', 0)
            break
    except Exception:
        continue
print(critical)
" 2>/dev/null || echo "0")

      HIGH=$(echo "$AUDIT_OUTPUT" | python3 -c "
import json, sys
high = 0
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        if obj.get('type') == 'auditSummary':
            high = obj.get('data', {}).get('vulnerabilities', {}).get('high', 0)
            break
    except Exception:
        continue
print(high)
" 2>/dev/null || echo "0")

      if [ -n "$AUDIT_OUTPUT" ] && [ "$CRITICAL" = "0" ] && [ "$HIGH" = "0" ]; then
        HAS_SUMMARY=$(echo "$AUDIT_OUTPUT" | grep -c "auditSummary" 2>/dev/null || echo "0")
        if [ "$HAS_SUMMARY" = "0" ]; then
          echo "WARNING: Yarn audit output could not be parsed. Run 'yarn audit' manually." >&2
        fi
      fi
    else
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
    fi

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
      echo "WARNING: $PIP_CRITICAL Python vulnerabilities found. Run 'pip-audit' for details." >&2
    fi
  fi
fi

exit 0
