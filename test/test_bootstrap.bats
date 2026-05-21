#!/usr/bin/env bats
# Smoke tests for bootstrap.sh
# Run: bats test/test_bootstrap.bats
# Requires: bats-core (brew install bats-core)

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
BOOTSTRAP="$REPO_ROOT/bootstrap.sh"

# ── Helpers ────────────────────────────────────────────────────────────────────
setup() {
  # Each test gets a fresh temp directory
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Run bootstrap in dry-run mode (non-interactive, no filesystem side effects)
run_dry() {
  run bash "$BOOTSTRAP" --dry-run "$@" "$TEST_DIR"
}

# Run bootstrap piping a single character for the team/solo prompt
run_install() {
  local platform="$1"; shift
  local answer="${1:-s}"
  # Pass the answer through a file redirect to avoid pipe issues
  local input_file
  input_file="$(mktemp)"
  printf '%s\n' "$answer" > "$input_file"
  run bash "$BOOTSTRAP" "--$platform" "$TEST_DIR" < "$input_file"
  rm -f "$input_file"
}

# ── --help ─────────────────────────────────────────────────────────────────────
@test "--help exits 0 and prints usage" {
  run bash "$BOOTSTRAP" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "no flags exits 1 and shows error" {
  run bash "$BOOTSTRAP"
  [ "$status" -eq 1 ]
  [[ "$output" == *"platform flag required"* ]]
}

@test "unknown flag exits 1" {
  run bash "$BOOTSTRAP" --foobar
  [ "$status" -eq 1 ]
}

# ── --dry-run ──────────────────────────────────────────────────────────────────
@test "--dry-run --cursor prints dry-run output and creates no files" {
  run_dry --cursor
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [[ "$output" == *"Cursor"* ]]
  # Nothing should have been created
  [ ! -d "$TEST_DIR/.cursor" ]
}

@test "--dry-run --claude prints dry-run output and creates no files" {
  run_dry --claude
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [[ "$output" == *"Claude"* ]]
  [ ! -d "$TEST_DIR/.claude" ]
}

@test "--dry-run --both prints output for both platforms" {
  run_dry --both
  [ "$status" -eq 0 ]
  [[ "$output" == *"Claude"* ]]
  [[ "$output" == *"Cursor"* ]]
  [ ! -d "$TEST_DIR/.cursor" ]
  [ ! -d "$TEST_DIR/.claude" ]
}

# ── New project install ────────────────────────────────────────────────────────
@test "cursor install on new project creates .cursor/ and AGENTS.md" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.cursor" ]
  [ -f "$TEST_DIR/AGENTS.md" ]
}

@test "claude install on new project creates .claude/ and CLAUDE.md" {
  run_install claude s
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.claude" ]
  [ -f "$TEST_DIR/CLAUDE.md" ]
}

@test "cursor install creates skills/ directory" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.cursor/skills" ]
}

@test "cursor install creates rules/ directory" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.cursor/rules" ]
}

@test "cursor install creates hooks/ directory" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.cursor/hooks" ]
}

@test "cursor install creates hooks.json" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.cursor/hooks.json" ]
}

@test "cursor install creates mcp.json.example" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.cursor/mcp.json.example" ]
}

@test "cursor install stamps version file" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.cursor/.aiagent-init-version" ]
}

@test "cursor install makes hook scripts executable" {
  run_install cursor s
  [ "$status" -eq 0 ]
  for hook in "$TEST_DIR/.cursor/hooks"/*.py "$TEST_DIR/.cursor/hooks"/*.sh; do
    [ -x "$hook" ]
  done
}

# ── Gitignore — solo mode ──────────────────────────────────────────────────────
@test "cursor solo install adds .cursor/ entries to .gitignore" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.gitignore" ]
  grep -qF ".cursor/skills/" "$TEST_DIR/.gitignore"
  grep -qF "AGENTS.md" "$TEST_DIR/.gitignore"
}

@test "claude solo install adds .claude/ to .gitignore" {
  run_install claude s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.gitignore" ]
  grep -qF ".claude/" "$TEST_DIR/.gitignore"
}

# ── Gitignore — team mode ──────────────────────────────────────────────────────
@test "cursor team install adds only personal files to .gitignore" {
  run_install cursor t
  [ "$status" -eq 0 ]
  # Should contain session-notes but NOT .cursor/skills/
  grep -qF ".cursor/session-notes.md" "$TEST_DIR/.gitignore"
  ! grep -qF ".cursor/skills/" "$TEST_DIR/.gitignore"
}

# ── Scaffold validation ────────────────────────────────────────────────────────
@test "cursor scaffold has project-setup skill" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.cursor/skills/project-setup/SKILL.md" ]
}

@test "cursor scaffold has all 9 rules" {
  run_install cursor s
  [ "$status" -eq 0 ]
  rule_count="$(find "$TEST_DIR/.cursor/rules" -type f | wc -l | tr -d ' ')"
  [ "$rule_count" -ge 9 ]
}

@test "cursor scaffold has Rust profile" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.cursor/skills/project-setup/profiles/rust.md" ]
}

@test "cursor scaffold has Django profile" {
  run_install cursor s
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.cursor/skills/project-setup/profiles/django.md" ]
}

# ── --verify ───────────────────────────────────────────────────────────────────
@test "--verify on empty dir exits 1 with helpful message" {
  run bash "$BOOTSTRAP" --verify "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No AI scaffold found"* ]]
}

@test "--verify after cursor install exits 0" {
  run_install cursor s
  run bash "$BOOTSTRAP" --verify "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installation looks healthy"* ]]
}

# ── Existing project detection ─────────────────────────────────────────────────
@test "detects existing project when package.json exists" {
  touch "$TEST_DIR/package.json"
  run_dry --cursor
  [ "$status" -eq 0 ]
  [[ "$output" == *"EXISTING PROJECT"* ]]
}

@test "detects new project when no markers present" {
  run_dry --cursor
  [ "$status" -eq 0 ]
  [[ "$output" == *"NEW PROJECT"* ]]
}

@test "detects existing project when Cargo.toml exists" {
  touch "$TEST_DIR/Cargo.toml"
  run_dry --cursor
  [ "$status" -eq 0 ]
  [[ "$output" == *"EXISTING PROJECT"* ]]
}

# ── Scaffold integrity ─────────────────────────────────────────────────────────
@test "scaffold/cursor directory exists in repo" {
  [ -d "$REPO_ROOT/scaffold/cursor" ]
}

@test "scaffold/claude directory exists in repo" {
  [ -d "$REPO_ROOT/scaffold/claude" ]
}

@test "scaffold/cursor has hooks.json" {
  [ -f "$REPO_ROOT/scaffold/cursor/.cursor/hooks.json" ]
}

@test "scaffold/claude has settings.json" {
  [ -f "$REPO_ROOT/scaffold/claude/.claude/settings.json" ]
}

@test "all scaffold hook scripts are executable" {
  for hook in "$REPO_ROOT"/scaffold/cursor/.cursor/hooks/*.py \
              "$REPO_ROOT"/scaffold/cursor/.cursor/hooks/*.sh \
              "$REPO_ROOT"/scaffold/claude/.claude/hooks/*.py \
              "$REPO_ROOT"/scaffold/claude/.claude/hooks/*.sh; do
    [ -x "$hook" ] || (echo "Not executable: $hook" && false)
  done
}
