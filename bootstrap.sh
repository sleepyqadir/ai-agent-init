#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD="$SCRIPT_DIR/scaffold"

# Handle --update flag
if [ "${1:-}" = "--update" ]; then
  TARGET="${2:-.}"
  if [ -d "$TARGET" ]; then
    TARGET="$(cd "$TARGET" && pwd)"
  fi

  echo "=== claude-init update ==="
  echo ""

  # Step 1: Pull latest template
  echo "Pulling latest template..."
  git -C "$SCRIPT_DIR" pull
  echo ""

  # Step 2: Overwrite safe files (skip CLAUDE.md and settings.json)
  echo "Syncing to: $TARGET"
  SAFE_DIRS=("agents" "skills" "rules" "hooks" "commands")
  for dir in "${SAFE_DIRS[@]}"; do
    src="$SCAFFOLD/.claude/$dir"
    dest="$TARGET/.claude/$dir"
    if [ -d "$src" ]; then
      rm -rf "$dest"
      cp -r "$src" "$dest"
      echo "  updated: .claude/$dir"
    fi
  done

  # Make hooks executable
  find "$TARGET/.claude/hooks" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
  find "$TARGET/.claude/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

  echo ""
  echo "Done. Your project is up to date."
  echo "Note: CLAUDE.md and settings.json were not touched."
  exit 0
fi

TARGET="${1:-.}"

if [ -d "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
else
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

echo "=== claude-init ==="
echo "Target: $TARGET"
echo ""

# Enforce: .git and .claude must always be at the git root.
# If the target is not the git root, warn and suggest the correct path.
GIT_ROOT=$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$GIT_ROOT" ] && [ "$GIT_ROOT" != "$TARGET" ]; then
  echo "Warning: You are not at the git root."
  echo "  Git root: $GIT_ROOT"
  echo "  Target:   $TARGET"
  echo ""
  echo ".git and .claude should always be at the git root."
  echo "Run from the git root instead:"
  echo ""
  echo "  cd $GIT_ROOT"
  echo "  claude-init ."
  echo ""
  read -rp "Continue anyway? [y/N]: " confirm
  case "$confirm" in
    y|Y) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
  echo ""
fi

# Detect if this looks like an existing project.
# Project files can be at root or inside a subfolder (monorepo / multi-project).
is_existing=false
has_project_files() {
  local dir="$1"
  [ -f "$dir/package.json" ] || [ -f "$dir/requirements.txt" ] || \
  [ -f "$dir/go.mod" ] || [ -f "$dir/Cargo.toml" ] || \
  [ -f "$dir/pyproject.toml" ] || [ -f "$dir/Pipfile" ] || \
  [ -d "$dir/src" ] || [ -d "$dir/app" ]
}

if [ -d "$TARGET/.git" ] || has_project_files "$TARGET"; then
  is_existing=true
else
  # Scan one level deep for monorepos / multi-project roots
  for subdir in "$TARGET"/*/; do
    if [ -d "$subdir" ] && has_project_files "$subdir"; then
      is_existing=true
      break
    fi
  done
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

# Ask whether this is a solo or team project
echo "Who is this setup for?"
echo ""
echo "  [t] Team — commit .claude/ to git so everyone shares the same setup"
echo "  [s] Solo — gitignore .claude/ (not everyone on the team uses Claude)"
echo ""
read -rp "Choose [t/s]: " team_choice
echo ""

# Build gitignore entries based on choice
if [ "${team_choice,,}" = "s" ]; then
  GITIGNORE_ENTRIES=(
    ".claude/"
    "CLAUDE.md"
    "CLAUDE.local.md"
    ".mcp.json.example"
  )
  echo "Solo mode — .claude/, CLAUDE.md and .mcp.json.example will be gitignored."
else
  GITIGNORE_ENTRIES=(
    ".claude/session-notes.md"
    ".claude/settings.local.json"
    ".claude/worktrees/"
    "CLAUDE.local.md"
  )
  echo "Team mode — .claude/ will be committed. Personal files stay gitignored."
fi
echo ""

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
