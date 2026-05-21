#!/usr/bin/env bats
# Tests for install.sh
# Run: bats test/test_install.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INSTALL="$REPO_ROOT/install.sh"

setup() {
  TEST_HOME="$(mktemp -d)"
  # Point HOME to a temp dir so we don't touch the real shell rc files
  export HOME="$TEST_HOME"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "install.sh exits 0 when no rc files exist (creates .zshrc)" {
  # SHELL=zsh should trigger .zshrc creation
  SHELL="/bin/zsh" run bash "$INSTALL"
  [ "$status" -eq 0 ]
  [ -f "$TEST_HOME/.zshrc" ]
  grep -qF "alias aiagent-init=" "$TEST_HOME/.zshrc"
}

@test "install.sh adds alias to existing .zshrc" {
  touch "$TEST_HOME/.zshrc"
  run bash "$INSTALL"
  [ "$status" -eq 0 ]
  grep -qF "alias aiagent-init=" "$TEST_HOME/.zshrc"
}

@test "install.sh detects already installed and reports it" {
  touch "$TEST_HOME/.zshrc"
  # Run once to install
  bash "$INSTALL" > /dev/null 2>&1
  # Run again — should report already installed
  run bash "$INSTALL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}

@test "install.sh updates stale alias pointing to different path" {
  echo 'alias aiagent-init="/old/path/bootstrap.sh"' > "$TEST_HOME/.zshrc"
  run bash "$INSTALL"
  [ "$status" -eq 0 ]
  # Old path should be gone
  ! grep -qF "/old/path/bootstrap.sh" "$TEST_HOME/.zshrc"
  # New path should be present
  grep -qF "alias aiagent-init=" "$TEST_HOME/.zshrc"
  [[ "$output" == *"updated"* ]]
}

@test "install.sh fails gracefully if bootstrap.sh missing" {
  # Temporarily rename bootstrap.sh
  local tmp
  tmp="$(mktemp)"
  mv "$REPO_ROOT/bootstrap.sh" "$tmp"
  run bash "$INSTALL"
  mv "$tmp" "$REPO_ROOT/bootstrap.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bootstrap.sh not found"* ]]
}

@test "install.sh outputs source command matching detected shell" {
  touch "$TEST_HOME/.zshrc"
  SHELL="/bin/zsh" run bash "$INSTALL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"source ~/.zshrc"* ]]
}
