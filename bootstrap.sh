#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD="$SCRIPT_DIR/scaffold"
TARGET="${1:-.}"

if [ -d "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
else
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

echo "=== claude-project-init ==="
echo "Target: $TARGET"
echo ""

# Detect if this looks like an existing project
is_existing=false
if [ -d "$TARGET/.git" ] && \
   { [ -f "$TARGET/package.json" ] || [ -f "$TARGET/requirements.txt" ] || \
     [ -f "$TARGET/go.mod" ] || [ -f "$TARGET/Cargo.toml" ] || \
     [ -d "$TARGET/src" ] || [ -d "$TARGET/app" ]; }; then
  is_existing=true
fi

if [ "$is_existing" = true ]; then
  echo "Detected: EXISTING PROJECT"
  echo "The /project-setup skill will analyze your codebase and generate"
  echo "a CLAUDE.md tailored to your actual code — not generic questions."
  echo ""
else
  echo "Detected: NEW PROJECT"
  echo "The /project-setup skill will interview you and generate"
  echo "a complete Claude Code setup for your stack."
  echo ""
fi

# Handle existing .claude/ directory
if [ -d "$TARGET/.claude" ]; then
  echo "Warning: .claude/ already exists in this project."
  echo ""
  echo "  [a] Abort"
  echo "  [m] Merge — add missing files, keep existing ones"
  echo "  [o] Overwrite — replace everything"
  echo ""
  read -rp "Choose [a/m/o]: " choice
  case "$choice" in
    m|M)
      echo "Merging..."
      find "$SCAFFOLD/.claude" -type f | while read -r src; do
        rel="${src#$SCAFFOLD/}"
        dest="$TARGET/$rel"
        if [ ! -f "$dest" ]; then
          mkdir -p "$(dirname "$dest")"
          cp "$src" "$dest"
          echo "  + $rel"
        else
          echo "  ~ $rel (kept existing)"
          if [ "$rel" = ".claude/settings.json" ]; then
            echo "  ! Existing .claude/settings.json kept. Review it manually to ensure hooks are registered."
          fi
        fi
      done
      ;;
    o|O)
      echo "Overwriting..."
      rm -rf "$TARGET/.claude"
      cp -r "$SCAFFOLD/.claude" "$TARGET/.claude"
      echo "  Scaffold copied."
      ;;
    *)
      echo "Aborted."
      exit 0
      ;;
  esac
else
  cp -r "$SCAFFOLD/.claude" "$TARGET/.claude"
  echo "Scaffold copied."
fi

# Copy .mcp.json.example if not present
if [ ! -f "$TARGET/.mcp.json.example" ] && [ -f "$SCAFFOLD/.mcp.json.example" ]; then
  cp "$SCAFFOLD/.mcp.json.example" "$TARGET/.mcp.json.example"
fi

# Create placeholder CLAUDE.md if none exists
if [ ! -f "$TARGET/CLAUDE.md" ]; then
  cat > "$TARGET/CLAUDE.md" << 'EOF'
# Project Name

> Run `/project-setup` in Claude Code to generate your full CLAUDE.md.

This is a placeholder. The setup skill will analyze your project (or interview
you for a new one) and generate a CLAUDE.md with:

- Project architecture and conventions
- Stack-specific rules and patterns
- Development workflow
- Verification and quality gates
EOF
fi

# Add session notes to gitignore
GITIGNORE_ENTRIES=(
  ".claude/session-notes.md"
  ".claude/settings.local.json"
  ".claude/worktrees/"
  "CLAUDE.local.md"
)

for entry in "${GITIGNORE_ENTRIES[@]}"; do
  if [ -f "$TARGET/.gitignore" ]; then
    if ! grep -q "$entry" "$TARGET/.gitignore" 2>/dev/null; then
      echo "$entry" >> "$TARGET/.gitignore"
    fi
  else
    echo "$entry" > "$TARGET/.gitignore"
  fi
done

# Make scripts and hooks executable
find "$TARGET/.claude/hooks" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
find "$TARGET/.claude/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo ""
echo "Done. Next steps:"
echo "  1. cd $TARGET"
echo "  2. Open Claude Code"
echo "  3. Run /project-setup"
echo ""
if [ "$is_existing" = true ]; then
  echo "For your existing project, Claude will read the codebase first,"
  echo "then generate a CLAUDE.md based on what it finds."
else
  echo "For your new project, Claude will ask you 12 questions"
  echo "and generate everything from scratch."
fi
echo ""
