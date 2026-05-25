#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Color output (TTY-gated) ──────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

info()    { printf "${BLUE}%s${NC}\n" "$*"; }
success() { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn()    { printf "${YELLOW}  ! %s${NC}\n" "$*" >&2; }
err()     { printf "${RED}Error: %s${NC}\n" "$*" >&2; }
header()  { printf "\n${BOLD}=== %s ===${NC}\n" "$*"; }

# ── Dry-run helpers ───────────────────────────────────────────────────────────
DRY_RUN=false

fs_cp()    { if $DRY_RUN; then info "  [dry-run] cp $*"; else cp "$@"; fi; }
fs_rm()    { if $DRY_RUN; then info "  [dry-run] rm -rf $*"; else rm "$@"; fi; }
fs_chmod() { if $DRY_RUN; then info "  [dry-run] chmod $*"; else chmod "$@"; fi; }
fs_write() {
  # fs_write <path> <content>
  if $DRY_RUN; then info "  [dry-run] write $1"; else printf '%s\n' "$2" > "$1"; fi
}
fs_append() {
  # fs_append <line> <file>
  if $DRY_RUN; then info "  [dry-run] append '$1' >> $2"; else printf '%s\n' "$1" >> "$2"; fi
}
fs_mkdir() { if $DRY_RUN; then info "  [dry-run] mkdir -p $*"; else mkdir "$@"; fi; }

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: aiagent-init [--claude|--cursor|--both] [options] <target-directory>

Platform flags:
  --claude    Install Claude Code scaffold (.claude/)
  --cursor    Install Cursor scaffold (.cursor/)
  --both      Install both Claude and Cursor scaffolds

Options:
  --update                Update an existing installation (overwrites skills/rules/hooks)
  --dry-run               Preview what would change without modifying anything
  --verify                Validate an existing installation
  --setup-daily-update    Configure automated daily standup Slack DM
  --daily-update          Send daily update now (requires setup)
  --disable-daily-update  Disable the scheduled daily update
  --help                  Show this help

Examples:
  aiagent-init --cursor .
  aiagent-init --both ~/Projects/my-project
  aiagent-init --update --cursor .
  aiagent-init --dry-run --cursor .
  aiagent-init --verify .
  aiagent-init --setup-daily-update
  aiagent-init --daily-update
  aiagent-init --disable-daily-update
EOF
}

# ── Parse flags ───────────────────────────────────────────────────────────────
PLATFORM=""
UPDATE=false
VERIFY=false
SETUP_DAILY_UPDATE=false
DAILY_UPDATE=false
DISABLE_DAILY_UPDATE=false
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)               PLATFORM="claude"; shift ;;
    --cursor)               PLATFORM="cursor"; shift ;;
    --both)                 PLATFORM="both";   shift ;;
    --update)               UPDATE=true;       shift ;;
    --dry-run)              DRY_RUN=true;      shift ;;
    --verify)               VERIFY=true;       shift ;;
    --setup-daily-update)   SETUP_DAILY_UPDATE=true; shift ;;
    --daily-update)         DAILY_UPDATE=true;        shift ;;
    --disable-daily-update) DISABLE_DAILY_UPDATE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    -*)        err "Unknown flag: $1"; echo ""; usage; exit 1 ;;
    *)         TARGET="$1"; shift ;;
  esac
done

if [ -z "$PLATFORM" ] && ! $VERIFY && ! $SETUP_DAILY_UPDATE && ! $DAILY_UPDATE && ! $DISABLE_DAILY_UPDATE; then
  err "platform flag required (--claude, --cursor, or --both)"
  echo ""
  usage
  exit 1
fi

[ -z "$TARGET" ] && TARGET="."

# ── Resolve target path ───────────────────────────────────────────────────────
if [ -d "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
elif ! $DRY_RUN; then
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

# ── Platform configuration (sets globals) ─────────────────────────────────────
# Safe to call multiple times; overwrites globals each time.
platform_config() {
  local p="$1"
  if [ "$p" = "claude" ]; then
    SCAFFOLD="$SCRIPT_DIR/scaffold/claude"
    CONFIG_DIR=".claude"
    CONTEXT_FILE="CLAUDE.md"
    PLATFORM_LABEL="Claude Code"
    SETUP_COMMAND="/project-setup"
    SAFE_DIRS="agents skills rules hooks commands"
    PLATFORM_CONFIG_FILE="settings.json"
  else
    SCAFFOLD="$SCRIPT_DIR/scaffold/cursor"
    CONFIG_DIR=".cursor"
    CONTEXT_FILE="AGENTS.md"
    PLATFORM_LABEL="Cursor"
    SETUP_COMMAND="project-setup skill"
    SAFE_DIRS="skills rules hooks"
    PLATFORM_CONFIG_FILE="hooks.json"
  fi
}

# ── Stamp version ─────────────────────────────────────────────────────────────
stamp_version() {
  # stamp_version <config_dir_path>
  local dir="$1"
  local sha=""
  if [ -d "$SCRIPT_DIR/.git" ]; then
    sha="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "")"
  fi
  [ -n "$sha" ] && fs_write "$dir/.aiagent-init-version" "$sha"
}

# ── Make hooks executable ─────────────────────────────────────────────────────
chmod_hooks() {
  local dir="$1"
  if $DRY_RUN; then
    info "  [dry-run] chmod +x $dir/hooks/*.{py,sh}"
    return
  fi
  find "$dir/hooks" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
  find "$dir/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
}

# ── Guard: safe path for rm -rf ───────────────────────────────────────────────
# Ensures the path we're about to delete contains the expected config dir segment.
assert_safe_path() {
  local path="$1"
  local required_segment="$2"
  case "$path" in
    *"$required_segment"*) return 0 ;;
  esac
  err "Refusing to remove unexpected path: $path"
  err "Expected path to contain: $required_segment"
  exit 1
}

# ── Verify mode ───────────────────────────────────────────────────────────────
verify_platform() {
  local p="$1"
  platform_config "$p"
  local healthy=true

  header "Verifying $PLATFORM_LABEL installation in $TARGET"
  echo ""

  if [ -d "$TARGET/$CONFIG_DIR" ]; then
    success "$CONFIG_DIR/ exists"
  else
    warn "$CONFIG_DIR/ not found — run: aiagent-init --$p ."
    healthy=false
  fi

  if [ -f "$TARGET/$CONTEXT_FILE" ]; then
    success "$CONTEXT_FILE exists"
  else
    warn "$CONTEXT_FILE not found"
    healthy=false
  fi

  if [ -d "$TARGET/$CONFIG_DIR/rules" ]; then
    local rule_count
    rule_count="$(find "$TARGET/$CONFIG_DIR/rules" -type f 2>/dev/null | wc -l | tr -d ' ')"
    success "rules/ found ($rule_count rules)"
  else
    warn "rules/ directory not found"
    healthy=false
  fi

  if [ -d "$TARGET/$CONFIG_DIR/skills" ]; then
    local skill_count
    skill_count="$(find "$TARGET/$CONFIG_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')"
    success "skills/ found ($skill_count skills)"
  else
    warn "skills/ directory not found"
    healthy=false
  fi

  local non_exec=0
  if [ -d "$TARGET/$CONFIG_DIR/hooks" ]; then
    while IFS= read -r hook; do
      if [ ! -x "$hook" ]; then
        warn "Not executable: $hook"
        non_exec=$((non_exec + 1))
        healthy=false
      fi
    done < <(find "$TARGET/$CONFIG_DIR/hooks" -type f \( -name "*.py" -o -name "*.sh" \) 2>/dev/null)
    [ "$non_exec" -eq 0 ] && success "All hooks are executable"
  else
    warn "hooks/ directory not found"
    healthy=false
  fi

  if [ -f "$TARGET/$CONFIG_DIR/.aiagent-init-version" ]; then
    local ver
    ver="$(cat "$TARGET/$CONFIG_DIR/.aiagent-init-version")"
    success "Scaffold version: $ver"
  else
    warn "No version stamp — run --update to stamp the installed version"
  fi

  echo ""
  if [ "$healthy" = true ]; then
    success "Installation looks healthy."
  else
    warn "Issues found. Re-run: aiagent-init --$p $TARGET"
    return 1
  fi
}

if $VERIFY; then
  if [ -z "$PLATFORM" ]; then
    found_any=false
    for p in claude cursor; do
      platform_config "$p"
      if [ -d "$TARGET/$CONFIG_DIR" ]; then
        verify_platform "$p"
        found_any=true
      fi
    done
    if [ "$found_any" = false ]; then
      warn "No AI scaffold found in $TARGET. Run aiagent-init --cursor . or --claude . first."
      exit 1
    fi
  elif [ "$PLATFORM" = "both" ]; then
    verify_platform "claude"
    verify_platform "cursor"
  else
    verify_platform "$PLATFORM"
  fi
  exit 0
fi

# ── Daily Update commands ──────────────────────────────────────────────────────
DAILY_UPDATE_CONFIG="$HOME/.aiagent-init/config.json"
DAILY_UPDATE_SCRIPT="$SCRIPT_DIR/daily-update-send.py"
DAILY_UPDATE_PLIST="$HOME/Library/LaunchAgents/com.aiagent-init.daily-update.plist"

# read_secret <prompt>: read without echo, return via REPLY
read_secret() {
  local prompt="$1"
  if [ -t 0 ]; then
    printf "%s" "$prompt"
    stty -echo 2>/dev/null || true
    IFS= read -r REPLY
    stty echo 2>/dev/null || true
    printf "\n"
  else
    IFS= read -r REPLY
  fi
}

if $SETUP_DAILY_UPDATE; then
  header "Daily Update — Automated Slack DM Setup"
  echo ""

  # Load existing credentials so we can skip re-prompting them
  EXISTING_SLACK_TOKEN=""
  EXISTING_SLACK_USER_ID=""
  EXISTING_LLM_PROVIDER=""
  EXISTING_LLM_KEY=""
  EXISTING_LLM_MODEL=""
  if [ -f "$DAILY_UPDATE_CONFIG" ]; then
    EXISTING_SLACK_TOKEN="$(python3 -c "import json; d=json.load(open('$DAILY_UPDATE_CONFIG')); print(d.get('daily_update',{}).get('slack_bot_token',''))" 2>/dev/null || echo "")"
    EXISTING_SLACK_USER_ID="$(python3 -c "import json; d=json.load(open('$DAILY_UPDATE_CONFIG')); print(d.get('daily_update',{}).get('slack_user_id',''))" 2>/dev/null || echo "")"
    EXISTING_LLM_PROVIDER="$(python3 -c "import json; d=json.load(open('$DAILY_UPDATE_CONFIG')); print(d.get('daily_update',{}).get('llm_provider',''))" 2>/dev/null || echo "")"
    EXISTING_LLM_KEY="$(python3 -c "import json; d=json.load(open('$DAILY_UPDATE_CONFIG')); print(d.get('daily_update',{}).get('llm_api_key',''))" 2>/dev/null || echo "")"
    EXISTING_LLM_MODEL="$(python3 -c "import json; d=json.load(open('$DAILY_UPDATE_CONFIG')); print(d.get('daily_update',{}).get('llm_model',''))" 2>/dev/null || echo "")"
  fi

  # Slack bot token
  if [ -n "$EXISTING_SLACK_TOKEN" ]; then
    MASKED="$(printf '%s' "$EXISTING_SLACK_TOKEN" | cut -c1-8)..."
    info "1. Slack Bot Token: using existing ($MASKED) — press Enter to keep, or type a new one"
    printf "   > "
    IFS= read -r INPUT_TOKEN
    SLACK_TOKEN="${INPUT_TOKEN:-$EXISTING_SLACK_TOKEN}"
  else
    read_secret "1. Slack Bot Token (xoxb-...): "
    SLACK_TOKEN="$REPLY"
  fi
  if [ -z "$SLACK_TOKEN" ]; then
    err "Slack bot token is required."
    exit 1
  fi
  case "$SLACK_TOKEN" in
    xoxb-*) ;;
    *) warn "Token doesn't start with 'xoxb-' — double-check it's a bot token." ;;
  esac

  # Slack user ID
  if [ -n "$EXISTING_SLACK_USER_ID" ]; then
    info "2. Slack User ID: using existing ($EXISTING_SLACK_USER_ID) — press Enter to keep, or type a new one"
    printf "   > "
    IFS= read -r INPUT_UID
    SLACK_USER_ID="${INPUT_UID:-$EXISTING_SLACK_USER_ID}"
  else
    echo ""
    echo "2. Your Slack User ID (starts with U)"
    echo "   Find it: open your Slack profile → click the three dots → 'Copy member ID'"
    printf "   User ID: "
    IFS= read -r SLACK_USER_ID
  fi
  if [ -z "$SLACK_USER_ID" ]; then
    err "Slack user ID is required."
    exit 1
  fi
  case "$SLACK_USER_ID" in
    U*) ;;
    *) warn "User ID doesn't start with 'U' — verify it from your Slack profile." ;;
  esac

  # LLM provider
  if [ -n "$EXISTING_LLM_PROVIDER" ]; then
    info "3. LLM Provider: using existing ($EXISTING_LLM_PROVIDER) — press Enter to keep, or type openai/anthropic"
    printf "   > "
    IFS= read -r INPUT_PROVIDER
    LLM_PROVIDER="${INPUT_PROVIDER:-$EXISTING_LLM_PROVIDER}"
  else
    echo ""
    printf "3. LLM Provider [openai/anthropic] (default: openai): "
    IFS= read -r LLM_PROVIDER
    LLM_PROVIDER="${LLM_PROVIDER:-openai}"
  fi
  LLM_PROVIDER="$(printf '%s' "$LLM_PROVIDER" | tr '[:upper:]' '[:lower:]')"
  if [ "$LLM_PROVIDER" != "openai" ] && [ "$LLM_PROVIDER" != "anthropic" ]; then
    err "Provider must be 'openai' or 'anthropic'."
    exit 1
  fi
  if [ "$LLM_PROVIDER" = "openai" ]; then
    DEFAULT_MODEL="gpt-4o-mini"
  else
    DEFAULT_MODEL="claude-3-haiku-20240307"
  fi

  # LLM API key
  if [ -n "$EXISTING_LLM_KEY" ]; then
    MASKED_KEY="$(printf '%s' "$EXISTING_LLM_KEY" | cut -c1-8)..."
    info "4. LLM API Key: using existing ($MASKED_KEY) — press Enter to keep, or type a new one"
    printf "   > "
    stty -echo 2>/dev/null || true
    IFS= read -r INPUT_KEY
    stty echo 2>/dev/null || true
    printf "\n"
    LLM_API_KEY="${INPUT_KEY:-$EXISTING_LLM_KEY}"
  else
    echo ""
    if [ "$LLM_PROVIDER" = "openai" ]; then
      read_secret "4. OpenAI API Key (sk-...): "
    else
      read_secret "4. Anthropic API Key (sk-ant-...): "
    fi
    LLM_API_KEY="$REPLY"
  fi
  if [ -z "$LLM_API_KEY" ]; then
    err "LLM API key is required."
    exit 1
  fi

  # Use existing model or cost-effective default; never prompt (user shouldn't need to know)
  LLM_MODEL="${EXISTING_LLM_MODEL:-$DEFAULT_MODEL}"

  # Send time
  echo ""
  printf "5. Preferred send time — 24h format (default: 18:00): "
  IFS= read -r SEND_TIME
  SEND_TIME="${SEND_TIME:-18:00}"
  SEND_HOUR="$(printf '%s' "$SEND_TIME" | cut -d: -f1)"
  SEND_MINUTE="$(printf '%s' "$SEND_TIME" | cut -d: -f2)"
  if [ -z "$SEND_HOUR" ] || [ -z "$SEND_MINUTE" ]; then
    err "Invalid time format. Use HH:MM (e.g., 18:00)."
    exit 1
  fi

  # Write config
  mkdir -p "$(dirname "$DAILY_UPDATE_CONFIG")"
  # Merge with existing config if present
  EXISTING_PROJECTS="[]"
  if [ -f "$DAILY_UPDATE_CONFIG" ]; then
    EXISTING_PROJECTS="$(python3 -c "
import json, sys
try:
    cfg = json.load(open('$DAILY_UPDATE_CONFIG'))
    print(json.dumps(cfg.get('daily_update', {}).get('projects', [])))
except Exception:
    print('[]')
" 2>/dev/null || echo "[]")"
  fi

  python3 - <<PYEOF
import json, os, stat

config_path = "$DAILY_UPDATE_CONFIG"
existing_projects = $EXISTING_PROJECTS

data = {}
if os.path.exists(config_path):
    try:
        with open(config_path) as f:
            data = json.load(f)
    except Exception:
        data = {}

data["daily_update"] = {
    "enabled": True,
    "slack_bot_token": "$SLACK_TOKEN",
    "slack_user_id": "$SLACK_USER_ID",
    "llm_provider": "$LLM_PROVIDER",
    "llm_api_key": "$LLM_API_KEY",
    "llm_model": "$LLM_MODEL",
    "send_time": "$SEND_TIME",
    "projects": existing_projects,
}

with open(config_path, "w") as f:
    json.dump(data, f, indent=2)
os.chmod(config_path, stat.S_IRUSR | stat.S_IWUSR)
print("Config saved.")
PYEOF

  echo ""
  success "Config saved to $DAILY_UPDATE_CONFIG (permissions: 600)"

  # Install launchd plist (macOS) or print crontab instructions (Linux)
  if [ "$(uname)" = "Darwin" ]; then
    mkdir -p "$(dirname "$DAILY_UPDATE_PLIST")"
    cat > "$DAILY_UPDATE_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.aiagent-init.daily-update</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(command -v python3)</string>
        <string>$DAILY_UPDATE_SCRIPT</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>$SEND_HOUR</integer>
        <key>Minute</key>
        <integer>$SEND_MINUTE</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/.aiagent-init/daily-update.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.aiagent-init/daily-update.log</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST
    launchctl unload "$DAILY_UPDATE_PLIST" 2>/dev/null || true
    launchctl load "$DAILY_UPDATE_PLIST" 2>/dev/null && \
      success "Installed launchd plist — runs daily at $SEND_TIME" || \
      warn "Could not load plist automatically. Run: launchctl load $DAILY_UPDATE_PLIST"
  else
    echo ""
    info "Linux detected. Add this cron entry manually:"
    echo ""
    echo "  crontab -e"
    echo ""
    echo "  $SEND_MINUTE $SEND_HOUR * * * $(command -v python3) $DAILY_UPDATE_SCRIPT >> $HOME/.aiagent-init/daily-update.log 2>&1"
    echo ""
  fi

  echo ""
  echo "  Disable:  aiagent-init --disable-daily-update"
  echo "  Test now: aiagent-init --daily-update"
  echo ""
  exit 0
fi

if $DAILY_UPDATE; then
  if [ ! -f "$DAILY_UPDATE_SCRIPT" ]; then
    err "daily-update-send.py not found at $DAILY_UPDATE_SCRIPT"
    err "Is the aiagent-init repo intact?"
    exit 1
  fi
  python3 "$DAILY_UPDATE_SCRIPT" "$@"
  exit $?
fi

if $DISABLE_DAILY_UPDATE; then
  if [ ! -f "$DAILY_UPDATE_CONFIG" ]; then
    warn "No config found at $DAILY_UPDATE_CONFIG — nothing to disable."
    exit 0
  fi

  # Unload launchd plist on macOS
  if [ "$(uname)" = "Darwin" ] && [ -f "$DAILY_UPDATE_PLIST" ]; then
    launchctl unload "$DAILY_UPDATE_PLIST" 2>/dev/null || true
    success "Unloaded launchd plist"
  fi

  # Set enabled=false in config
  python3 - <<PYEOF
import json, os, stat

config_path = "$DAILY_UPDATE_CONFIG"
try:
    with open(config_path) as f:
        data = json.load(f)
except Exception:
    data = {}

if "daily_update" not in data:
    data["daily_update"] = {}

data["daily_update"]["enabled"] = False

with open(config_path, "w") as f:
    json.dump(data, f, indent=2)
os.chmod(config_path, stat.S_IRUSR | stat.S_IWUSR)
print("Marked as disabled.")
PYEOF

  success "Daily update disabled."
  echo "  Re-enable: aiagent-init --setup-daily-update"
  echo ""
  exit 0
fi

# ── Update mode ───────────────────────────────────────────────────────────────
update_platform() {
  local p="$1"
  platform_config "$p"

  header "aiagent-init update ($PLATFORM_LABEL)"
  echo "Target: $TARGET"
  echo ""

  if [ ! -d "$SCAFFOLD/$CONFIG_DIR" ]; then
    err "Scaffold not found: $SCAFFOLD/$CONFIG_DIR"
    err "Is the aiagent-init repo intact?"
    exit 1
  fi

  if [ -d "$SCRIPT_DIR/.git" ]; then
    info "Pulling latest template..."
    if ! git -C "$SCRIPT_DIR" pull 2>&1; then
      warn "git pull failed (local changes or no network). Continuing with current scaffold."
    fi
    echo ""
  else
    warn "Not a git clone — skipping pull, using local scaffold."
    echo ""
  fi

  local new_sha=""
  if [ -d "$SCRIPT_DIR/.git" ]; then
    new_sha="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "")"
  fi

  info "Syncing $CONFIG_DIR/ ..."

  for dir in $SAFE_DIRS; do
    local src="$SCAFFOLD/$CONFIG_DIR/$dir"
    local dest="$TARGET/$CONFIG_DIR/$dir"
    if [ -d "$src" ]; then
      assert_safe_path "$dest" "$CONFIG_DIR"
      $DRY_RUN || rm -rf "$dest"
      fs_cp -r "$src" "$dest"
      info "  updated: $CONFIG_DIR/$dir"
    fi
  done

  # Also sync the platform config file (hooks.json / settings.json)
  local cfg_src="$SCAFFOLD/$CONFIG_DIR/$PLATFORM_CONFIG_FILE"
  local cfg_dest="$TARGET/$CONFIG_DIR/$PLATFORM_CONFIG_FILE"
  if [ -f "$cfg_src" ]; then
    fs_cp "$cfg_src" "$cfg_dest"
    info "  updated: $CONFIG_DIR/$PLATFORM_CONFIG_FILE"
  fi

  chmod_hooks "$TARGET/$CONFIG_DIR"

  if [ -n "$new_sha" ]; then
    stamp_version "$TARGET/$CONFIG_DIR"
    info "  version: $new_sha"
  fi

  echo ""
  success "Done. $PLATFORM_LABEL is up to date."
  info "Note: $CONTEXT_FILE and your custom files were not touched."
}

if $UPDATE; then
  $DRY_RUN && warn "[dry-run] No files will be modified." && echo ""
  if [ "$PLATFORM" = "both" ]; then
    update_platform "claude"
    update_platform "cursor"
  else
    update_platform "$PLATFORM"
  fi
  exit 0
fi

# ── Main install ──────────────────────────────────────────────────────────────
$DRY_RUN && warn "[dry-run] No files will be modified." && echo ""

# Git root check (done once — independent of platform)
GIT_ROOT="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -n "$GIT_ROOT" ] && [ "$GIT_ROOT" != "$TARGET" ]; then
  warn "You are not at the git root."
  echo "  Git root: $GIT_ROOT"
  echo "  Target:   $TARGET"
  echo ""
  warn "The config dir should live at the git root."
  echo ""
  if $DRY_RUN; then
    info "  [dry-run] Continuing (would prompt in real run)."
    echo ""
  else
    read -rp "Continue anyway? [y/N]: " confirm
    case "$confirm" in
      y|Y) echo "" ;;
      *) echo "Aborted."; exit 0 ;;
    esac
  fi
fi

# Detect new vs existing project
is_existing=false
has_project_files() {
  local dir="$1"
  [ -f "$dir/package.json" ] || [ -f "$dir/requirements.txt" ] || \
  [ -f "$dir/go.mod" ]      || [ -f "$dir/Cargo.toml" ]       || \
  [ -f "$dir/pyproject.toml" ] || [ -f "$dir/Pipfile" ]       || \
  [ -d "$dir/src" ]         || [ -d "$dir/app" ]
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

install_platform() {
  local p="$1"
  platform_config "$p"

  header "aiagent-init ($PLATFORM_LABEL)"
  echo "Target: $TARGET"
  echo ""

  if [ ! -d "$SCAFFOLD" ]; then
    err "Scaffold not found: $SCAFFOLD"
    err "Is the aiagent-init repo intact? Try: cd $SCRIPT_DIR && git status"
    exit 1
  fi

  if [ "$is_existing" = true ]; then
    info "Detected: EXISTING PROJECT"
    echo "The $SETUP_COMMAND will analyze your codebase and generate"
    echo "a $CONTEXT_FILE tailored to your actual code — not generic questions."
    echo ""
  else
    info "Detected: NEW PROJECT"
    echo "The $SETUP_COMMAND will interview you and generate"
    echo "a complete $PLATFORM_LABEL setup for your stack."
    echo ""
  fi

  # Handle existing config directory
  if [ -d "$TARGET/$CONFIG_DIR" ]; then
    warn "$CONFIG_DIR/ already exists in this project."
    echo ""
    echo "  [a] Abort"
    echo "  [m] Merge — add missing files, keep existing ones"
    echo "  [o] Overwrite — replace everything"
    echo ""
    if $DRY_RUN; then
      info "  [dry-run] Simulating merge..."
      choice="m"
    else
      read -rp "Choose [a/m/o]: " choice
    fi
    case "$choice" in
      m|M)
        echo ""
        info "Merging..."
        find "$SCAFFOLD/$CONFIG_DIR" -type f | while IFS= read -r src; do
          rel="${src#$SCAFFOLD/}"
          dest="$TARGET/$rel"
          if [ ! -f "$dest" ]; then
            $DRY_RUN || mkdir -p "$(dirname "$dest")"
            fs_cp "$src" "$dest"
            success "+ $rel"
          else
            info "  ~ $rel (kept existing)"
          fi
        done
        chmod_hooks "$TARGET/$CONFIG_DIR"
        ;;
      o|O)
        echo ""
        info "Overwriting..."
        assert_safe_path "$TARGET/$CONFIG_DIR" "$CONFIG_DIR"
        $DRY_RUN || rm -rf "$TARGET/$CONFIG_DIR"
        fs_cp -r "$SCAFFOLD/$CONFIG_DIR" "$TARGET/$CONFIG_DIR"
        success "Scaffold copied."
        ;;
      *)
        echo "Aborted."
        exit 0
        ;;
    esac
  else
    fs_cp -r "$SCAFFOLD/$CONFIG_DIR" "$TARGET/$CONFIG_DIR"
    success "Scaffold copied."
  fi

  # Copy .mcp.json.example if available and not already present.
  # Claude puts it at project root; Cursor puts it inside .cursor/
  if [ "$p" = "claude" ]; then
    if [ -f "$SCAFFOLD/.mcp.json.example" ] && [ ! -f "$TARGET/.mcp.json.example" ]; then
      fs_cp "$SCAFFOLD/.mcp.json.example" "$TARGET/.mcp.json.example"
    fi
  else
    if [ -f "$SCAFFOLD/$CONFIG_DIR/mcp.json.example" ] && [ ! -f "$TARGET/$CONFIG_DIR/mcp.json.example" ]; then
      fs_cp "$SCAFFOLD/$CONFIG_DIR/mcp.json.example" "$TARGET/$CONFIG_DIR/mcp.json.example"
    fi
  fi

  # Create placeholder context file if none exists
  if [ ! -f "$TARGET/$CONTEXT_FILE" ] && ! $DRY_RUN; then
    if [ "$p" = "claude" ]; then
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

  chmod_hooks "$TARGET/$CONFIG_DIR"
  stamp_version "$TARGET/$CONFIG_DIR"
}

# ── Run installs ──────────────────────────────────────────────────────────────
if [ "$PLATFORM" = "both" ]; then
  install_platform "claude"
  install_platform "cursor"
else
  install_platform "$PLATFORM"
fi

# ── Team / solo gitignore ─────────────────────────────────────────────────────
echo ""
echo "Who is this setup for?"
echo ""
echo "  [t] Team — commit config to git so everyone shares the same setup"
echo "  [s] Solo — gitignore config (not everyone on the team uses these tools)"
echo ""
if $DRY_RUN; then
  info "  [dry-run] Simulating solo mode for gitignore preview..."
  team_choice="s"
else
  read -rp "Choose [t/s]: " team_choice
fi
echo ""

team_choice_lower="$(printf '%s' "$team_choice" | tr '[:upper:]' '[:lower:]')"

apply_gitignore() {
  local p="$1"
  local mode="$2"
  platform_config "$p"

  local entries=""
  if [ "$mode" = "s" ]; then
    if [ "$p" = "claude" ]; then
      entries=".claude/ CLAUDE.md CLAUDE.local.md .mcp.json.example .claude/.aiagent-init-version .claude/token-usage.jsonl .claude/daily-updates.jsonl"
    else
      entries=".cursor/skills/ .cursor/rules/ .cursor/hooks/ .cursor/hooks.json AGENTS.md .cursor/session-notes.md .cursor/mcp.json.example .cursor/.aiagent-init-version .cursor/token-usage.jsonl .cursor/daily-updates.jsonl"
    fi
    info "Solo ($PLATFORM_LABEL) — $CONFIG_DIR/ and $CONTEXT_FILE will be gitignored."
  else
    if [ "$p" = "claude" ]; then
      entries=".claude/session-notes.md .claude/settings.local.json .claude/worktrees/ .claude/plans/ CLAUDE.local.md .claude/.aiagent-init-version .claude/token-usage.jsonl .claude/daily-updates.jsonl"
    else
      entries=".cursor/session-notes.md .cursor/mcp.json .cursor/plans/ .cursor/.aiagent-init-version .cursor/token-usage.jsonl .cursor/daily-updates.jsonl"
    fi
    info "Team ($PLATFORM_LABEL) — $CONFIG_DIR/ will be committed. Personal files stay gitignored."
  fi

  for entry in $entries; do
    if [ -f "$TARGET/.gitignore" ]; then
      # Use -F (fixed string) to avoid regex interpretation of the pattern
      if ! grep -qF "$entry" "$TARGET/.gitignore" 2>/dev/null; then
        fs_append "$entry" "$TARGET/.gitignore"
      fi
    else
      if ! $DRY_RUN; then
        printf '%s\n' "$entry" > "$TARGET/.gitignore"
      else
        info "  [dry-run] create $TARGET/.gitignore with $entry"
      fi
    fi
  done
}

if [ "$PLATFORM" = "both" ]; then
  apply_gitignore "claude" "$team_choice_lower"
  apply_gitignore "cursor" "$team_choice_lower"
else
  apply_gitignore "$PLATFORM" "$team_choice_lower"
fi

# ── Register project with daily-update config (if configured) ─────────────────
if [ -f "$DAILY_UPDATE_CONFIG" ] && ! $DRY_RUN; then
  python3 - <<PYEOF 2>/dev/null || true
import json, os, stat

config_path = "$DAILY_UPDATE_CONFIG"
project_dir = "$TARGET"
try:
    with open(config_path) as f:
        data = json.load(f)
    if "daily_update" in data:
        projects = data["daily_update"].get("projects", [])
        if project_dir not in projects:
            projects.append(project_dir)
            data["daily_update"]["projects"] = projects
            with open(config_path, "w") as f:
                json.dump(data, f, indent=2)
            os.chmod(config_path, stat.S_IRUSR | stat.S_IWUSR)
except Exception:
    pass
PYEOF
fi

# ── Final output ──────────────────────────────────────────────────────────────
echo ""
success "Done."
echo ""
echo "Next steps:"

show_next_steps() {
  local p="$1"
  platform_config "$p"
  echo "  1. cd $TARGET"
  echo "  2. Open $PLATFORM_LABEL"
  if [ "$p" = "claude" ]; then
    echo "  3. Run /project-setup"
  else
    echo "  3. In the chat, type: use the project-setup skill"
  fi
}

if [ "$PLATFORM" = "both" ]; then
  echo ""
  echo "Claude Code:"
  show_next_steps "claude"
  echo ""
  echo "Cursor:"
  show_next_steps "cursor"
else
  show_next_steps "$PLATFORM"
fi

echo ""
if [ "$is_existing" = true ]; then
  echo "For your existing project, the AI will read the codebase first,"
  echo "then generate a context file based on what it finds."
else
  echo "For your new project, the AI will ask you questions"
  echo "and generate everything from scratch."
fi
echo ""
