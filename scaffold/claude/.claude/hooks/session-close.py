#!/usr/bin/env python3
"""
Session Close Hook (stop event)
Checks for loose ends and writes a 3-line session summary.
Does not block (always exits 0) — prompts and logs only.
"""

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
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    os.chdir(project_dir)

    warnings = []
    artifact_hits = []

    git_status = run("git status --short 2>/dev/null")
    if git_status:
        file_count = len([l for l in git_status.split("\n") if l.strip()])
        warnings.append(f"{file_count} uncommitted file(s)")

    unpushed = run("git log @{u}..HEAD --oneline 2>/dev/null")
    if unpushed:
        commit_count = len([l for l in unpushed.split("\n") if l.strip()])
        warnings.append(f"{commit_count} unpushed commit(s)")

    # Check for debug artifacts in recently changed files
    changed_files = run("git diff --name-only HEAD 2>/dev/null")
    if changed_files:
        artifact_hits = []
        for fname in changed_files.split("\n"):
            fname = fname.strip()
            if not fname or not os.path.isfile(fname):
                continue
            try:
                with open(fname, encoding="utf-8", errors="ignore") as fh:
                    for i, line in enumerate(fh, 1):
                        stripped = line.strip()
                        if any(tag in stripped for tag in ("TODO", "FIXME", "HACK", "XXX", "console.log", "print(", "debugger")):
                            artifact_hits.append(f"  {fname}:{i}: {stripped[:80]}")
                            if len(artifact_hits) >= 5:
                                break
            except OSError:
                continue
        if artifact_hits:
            warnings.append(f"{len(artifact_hits)} debug artifact(s) in changed files")

    if warnings:
        print(f"\nBefore closing: {', '.join(warnings)}.", file=sys.stderr)
        if artifact_hits:
            print("Debug artifacts found (first 5):", file=sys.stderr)
            for hit in artifact_hits[:5]:
                print(hit, file=sys.stderr)
        print(
            "Consider using the commit or ship skills to save your work.",
            file=sys.stderr,
        )

    notes_path = os.path.join(project_dir, ".claude", "session-notes.md")
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
