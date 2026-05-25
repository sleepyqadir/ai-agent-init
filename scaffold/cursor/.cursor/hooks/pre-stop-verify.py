#!/usr/bin/env python3
"""
Pre-Stop Verification Reminder Hook (stop event)
Warns when uncommitted changes exist but verification does not appear to have run.
Does not block (always exits 0) — warn only.
Runs before session-close.py.
"""

import os
import subprocess
import sys


def run(cmd):
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip()
    except Exception:
        return ""


def session_appears_verified(project_dir, config_dir):
    """
    Heuristic: check if the current session has run verification.
    Looks for VERIFIED marker in session notes (written by verify skill).
    Also checks if any recent commit messages mention test/build/lint.
    """
    notes_path = os.path.join(project_dir, config_dir, "session-notes.md")
    if os.path.exists(notes_path):
        try:
            with open(notes_path, encoding="utf-8") as f:
                content = f.read(4000)
            if "VERIFIED" in content or "Tests: PASS" in content:
                return True
        except OSError:
            pass

    # Check recent commits for verification evidence
    recent_commits = run("git log --oneline -5 2>/dev/null")
    if recent_commits:
        lower = recent_commits.lower()
        if any(kw in lower for kw in ("test", "lint", "build", "verify", "fix:", "feat:")):
            return True

    return False


def main():
    project_dir = os.environ.get("CURSOR_WORKSPACE_PATH", os.getcwd())
    os.chdir(project_dir)
    config_dir = ".cursor"

    # Only warn if there are uncommitted changes
    git_status = run("git status --short 2>/dev/null")
    if not git_status:
        sys.exit(0)

    # Skip if verification appears to have run
    if session_appears_verified(project_dir, config_dir):
        sys.exit(0)

    changed_count = len([l for l in git_status.split("\n") if l.strip()])
    print(
        f"\nWARNING: {changed_count} uncommitted file(s) detected but verification does not appear to have run.\n"
        "Consider using the ship or verify skill before closing.",
        file=sys.stderr,
    )

    sys.exit(0)


if __name__ == "__main__":
    main()
