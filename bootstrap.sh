#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: aiagent-init [--claude|--cursor] [--update] <target-directory>

Platform flags (required):
  --claude    Install Claude Code scaffold (.claude/)
  --cursor    Install Cursor scaffold (.cursor/)

Options:
  --update    Update an existing installation (overwrites agents/skills/rules/hooks/commands)

Examples:
  aiagent-init --claude .
  aiagent-init --cursor .
  aiagent-init --update --claude .
  aiagent-init --update --cursor ~/Projects/my-project
EOF
}

# ── Parse flags ──────────────────────────────────────────────────────────────

PLATFORM=""
UPDATE=false
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude) PLATFORM="claude"; shift ;;
    --cursor) PLATFORM="cursor"; shift ;;
    --update) UPDATE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    -*) echo "Unknown flag: $1"; usage; exit 1 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  echo "Error: platform flag required (--claude or --cursor)"
  echo ""
  usage
  exit 1
fi

if [ -z "$TARGET" ]; then
  TARGET="."
fi

# ── Platform-specific settings ───────────────────────────────────────────────

SCAFFOLD="$SCRIPT_DIR/scaffold/$PLATFORM"

if [ "$PLATFORM" = "claude" ]; then
  CONFIG_DIR=".claude"
  CONTEXT_FILE="CLAUDE.md"
  PLATFORM_LABEL="Claude Code"
  SETUP_COMMAND="/project-setup"
  SAFE_DIRS=("agents" "skills" "rules" "hooks" "commands")
else
  CONFIG_DIR=".cursor"
  CONTEXT_FILE="AGENTS.md"
  PLATFORM_LABEL="Cursor"
  SETUP_COMMAND="project-setup skill"
  SAFE_DIRS=("skills" "rules" "hooks")
fi

# ── Resolve target path ──────────────────────────────────────────────────────

if [ -d "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
else
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

# ── Handle --update flag ─────────────────────────────────────────────────────

if [ "$UPDATE" = true ]; then
  echo "=== aiagent-init update ($PLATFORM_LABEL) ==="
  echo ""

  echo "Pulling latest template..."
  git -C "$SCRIPT_DIR" pull
  echo ""

  echo "Syncing to: $TARGET"
  for dir in "${SAFE_DIRS[@]}"; do
    src="$SCAFFOLD/$CONFIG_DIR/$dir"
    dest="$TARGET/$CONFIG_DIR/$dir"
    if [ -d "$src" ]; then
      rm -rf "$dest"
      cp -r "$src" "$dest"
      echo "  updated: $CONFIG_DIR/$dir"
    fi
  done

  # Make hooks executable
  find "$TARGET/$CONFIG_DIR/hooks" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
  find "$TARGET/$CONFIG_DIR/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

  echo ""
  echo "Done. Your project is up to date."
  echo "Note: $CONTEXT_FILE and platform config were not touched."
  exit 0
fi

# ── Main install ─────────────────────────────────────────────────────────────

echo "=== aiagent-init ($PLATFORM_LABEL) ==="
echo "Target: $TARGET"
echo ""

# Enforce: config dir must be at the git root.
GIT_ROOT=$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$GIT_ROOT" ] && [ "$GIT_ROOT" != "$TARGET" ]; then
  echo "Warning: You are not at the git root."
  echo "  Git root: $GIT_ROOT"
  echo "  Target:   $TARGET"
  echo ""
  echo "$CONFIG_DIR/ should be at the git root."
  echo "Run from the git root instead:"
  echo ""
  echo "  cd $GIT_ROOT"
  echo "  aiagent-init --$PLATFORM ."
  echo ""
  read -rp "Continue anyway? [y/N]: " confirm
  case "$confirm" in
    y|Y) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
  echo ""
fi

# Detect if this looks like an existing project.
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
  for subdir in "$TARGET"/*/; do
    if [ -d "$subdir" ] && has_project_files "$subdir"; then
      is_existing=true
      break
    fi
  done
fi

if [ "$is_existing" = true ]; then
  echo "Detected: EXISTING PROJECT"
  echo "The $SETUP_COMMAND will analyze your codebase and generate"
  echo "a $CONTEXT_FILE tailored to your actual code — not generic questions."
  echo ""
else
  echo "Detected: NEW PROJECT"
  echo "The $SETUP_COMMAND will interview you and generate"
  echo "a complete $PLATFORM_LABEL setup for your stack."
  echo ""
fi

# Handle existing config directory
if [ -d "$TARGET/$CONFIG_DIR" ]; then
  echo "Warning: $CONFIG_DIR/ already exists in this project."
  echo ""
  echo "  [a] Abort"
  echo "  [m] Merge — add missing files, keep existing ones"
  echo "  [o] Overwrite — replace everything"
  echo ""
  read -rp "Choose [a/m/o]: " choice
  case "$choice" in
    m|M)
      echo "Merging..."
      find "$SCAFFOLD/$CONFIG_DIR" -type f | while read -r src; do
        rel="${src#$SCAFFOLD/}"
        dest="$TARGET/$rel"
        if [ ! -f "$dest" ]; then
          mkdir -p "$(dirname "$dest")"
          cp "$src" "$dest"
          echo "  + $rel"
        else
          echo "  ~ $rel (kept existing)"
        fi
      done
      ;;
    o|O)
      echo "Overwriting..."
      rm -rf "$TARGET/$CONFIG_DIR"
      cp -r "$SCAFFOLD/$CONFIG_DIR" "$TARGET/$CONFIG_DIR"
      echo "  Scaffold copied."
      ;;
    *)
      echo "Aborted."
      exit 0
      ;;
  esac
else
  cp -r "$SCAFFOLD/$CONFIG_DIR" "$TARGET/$CONFIG_DIR"
  echo "Scaffold copied."
fi

# Copy .mcp.json.example if available and not present
if [ -f "$SCAFFOLD/.mcp.json.example" ] && [ ! -f "$TARGET/.mcp.json.example" ]; then
  cp "$SCAFFOLD/.mcp.json.example" "$TARGET/.mcp.json.example"
fi

# Create placeholder context file if none exists
if [ ! -f "$TARGET/$CONTEXT_FILE" ]; then
  if [ "$PLATFORM" = "claude" ]; then
    cat > "$TARGET/$CONTEXT_FILE" << 'EOF'
# Project Name

> Run `/project-setup` in Claude Code to generate your full CLAUDE.md.

This is a placeholder. The setup skill will analyze your project (or interview
you for a new one) and generate a CLAUDE.md with:

- Project architecture and conventions
- Stack-specific rules and patterns
- Development workflow
- Verification and quality gates
EOF
  else
    cat > "$TARGET/$CONTEXT_FILE" << 'EOF'
# Project Name

> Use the `project-setup` skill in Cursor to generate your full AGENTS.md.

This is a placeholder. The setup skill will analyze your project (or interview
you for a new one) and generate an AGENTS.md with:

- Project architecture and conventions
- Stack-specific rules and patterns
- Development workflow
- Verification and quality gates
EOF
  fi
fi

# Ask whether this is a solo or team project
echo ""
echo "Who is this setup for?"
echo ""
echo "  [t] Team — commit $CONFIG_DIR/ to git so everyone shares the same setup"
echo "  [s] Solo — gitignore $CONFIG_DIR/ (not everyone on the team uses $PLATFORM_LABEL)"
echo ""
read -rp "Choose [t/s]: " team_choice
echo ""

if [ "${team_choice,,}" = "s" ]; then
  if [ "$PLATFORM" = "claude" ]; then
    GITIGNORE_ENTRIES=(
      ".claude/"
      "CLAUDE.md"
      "CLAUDE.local.md"
      ".mcp.json.example"
    )
  else
    GITIGNORE_ENTRIES=(
      ".cursor/skills/"
      ".cursor/rules/"
      ".cursor/hooks/"
      ".cursor/hooks.json"
      "AGENTS.md"
      ".cursor/session-notes.md"
      ".cursor/mcp.json.example"
    )
  fi
  echo "Solo mode — $CONFIG_DIR/ and $CONTEXT_FILE will be gitignored."
else
  if [ "$PLATFORM" = "claude" ]; then
    GITIGNORE_ENTRIES=(
      ".claude/session-notes.md"
      ".claude/settings.local.json"
      ".claude/worktrees/"
      "CLAUDE.local.md"
    )
  else
    GITIGNORE_ENTRIES=(
      ".cursor/session-notes.md"
      ".cursor/mcp.json"
    )
  fi
  echo "Team mode — $CONFIG_DIR/ will be committed. Personal files stay gitignored."
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

# Make hook scripts executable
find "$TARGET/$CONFIG_DIR/hooks" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
find "$TARGET/$CONFIG_DIR/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo ""
echo "Done. Next steps:"
echo "  1. cd $TARGET"
echo "  2. Open $PLATFORM_LABEL"

if [ "$PLATFORM" = "claude" ]; then
  echo "  3. Run /project-setup"
  echo ""
  if [ "$is_existing" = true ]; then
    echo "For your existing project, Claude will read the codebase first,"
    echo "then generate a CLAUDE.md based on what it finds."
  else
    echo "For your new project, Claude will ask you 12 questions"
    echo "and generate everything from scratch."
  fi
else
  echo "  3. In the chat, type: use the project-setup skill"
  echo ""
  if [ "$is_existing" = true ]; then
    echo "For your existing project, Cursor will read the codebase first,"
    echo "then generate an AGENTS.md based on what it finds."
  else
    echo "For your new project, Cursor will ask you questions"
    echo "and generate everything from scratch."
  fi
fi
echo ""
