#!/usr/bin/env python3
"""
Session Close Hook (stop event)
Checks for loose ends and writes a 3-line session summary.
Does not block (always exits 0) — prompts and logs only.
"""

import json
import os
import subprocess
import sys
from datetime import datetime


def run(cmd):
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip()
    except Exception:
        return ""


def main():
    project_dir = os.environ.get("CURSOR_WORKSPACE_PATH", os.getcwd())
    os.chdir(project_dir)

    warnings = []

    git_status = run("git status --short 2>/dev/null")
    if git_status:
        file_count = len([l for l in git_status.split("\n") if l.strip()])
        warnings.append(f"{file_count} uncommitted file(s)")

    unpushed = run("git log @{u}..HEAD --oneline 2>/dev/null")
    if unpushed:
        commit_count = len([l for l in unpushed.split("\n") if l.strip()])
        warnings.append(f"{commit_count} unpushed commit(s)")

    if warnings:
        print(f"\nBefore closing: {', '.join(warnings)}.", file=sys.stderr)
        print(
            "Consider using the commit or ship skills to save your work.",
            file=sys.stderr,
        )

    notes_path = os.path.join(project_dir, ".cursor", "session-notes.md")
    os.makedirs(os.path.dirname(notes_path), exist_ok=True)

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    recent_commits = run("git log --oneline -3 2>/dev/null") or "No commits"

    summary = f"""## Session {timestamp}

Recent commits:
{recent_commits}

Uncommitted changes: {git_status if git_status else 'none'}

---
"""

    existing = ""
    if os.path.exists(notes_path):
        with open(notes_path) as f:
            existing = f.read()

    with open(notes_path, "w") as f:
        f.write(summary + existing)

    sys.exit(0)


if __name__ == "__main__":
    main()
