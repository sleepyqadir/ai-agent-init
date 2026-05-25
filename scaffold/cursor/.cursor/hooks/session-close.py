#!/usr/bin/env python3
"""
Session Close Hook (stop event)
Checks for loose ends, writes a structured session summary, detects
context drift that may require AGENTS.md updates, and appends a
structured entry to daily-updates.jsonl for automated standup generation.
Does not block (always exits 0) — prompts and logs only.
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone


def run(cmd):
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip()
    except Exception:
        return ""


def read_last_token_usage(project_dir, config_dir):
    log_path = os.path.join(project_dir, config_dir, "token-usage.jsonl")
    if not os.path.exists(log_path):
        return None
    try:
        with open(log_path, encoding="utf-8") as f:
            lines = [l.strip() for l in f if l.strip()]
        if not lines:
            return None
        last = json.loads(lines[-1])
        ctx = last.get("context_window", {})
        return ctx.get("used_pct")
    except Exception:
        return None


def list_active_plans(project_dir, config_dir):
    plans_dir = os.path.join(project_dir, config_dir, "plans")
    if not os.path.isdir(plans_dir):
        return []
    try:
        files = [
            f for f in os.listdir(plans_dir)
            if not f.startswith(".") and f.endswith((".md", ".txt", ".plan.md"))
        ]
        return sorted(files)[:5]
    except Exception:
        return []


CONTEXT_DRIFT_HEURISTICS = [
    {
        "id": "new_dependencies",
        "label": "new dependencies",
        "patterns": ["package.json", "requirements.txt", "Cargo.toml", "go.mod", "Gemfile", "pyproject.toml", "pom.xml", "build.gradle"],
    },
    {
        "id": "schema_changes",
        "label": "schema / migration changes",
        "patterns": ["migration", ".sql", "schema.", "alembic", "prisma/migrations"],
    },
    {
        "id": "new_config",
        "label": "new infrastructure / config files",
        "patterns": [".env.example", "docker-compose", "dockerfile", ".github/workflows", "kubernetes", "terraform", "pulumi"],
    },
]


def detect_context_drift(changed_files_raw):
    if not changed_files_raw:
        return []

    changed = [f.strip().lower() for f in changed_files_raw.split("\n") if f.strip()]
    triggered = []

    # Heuristic: large scope (10+ files)
    if len(changed) >= 10:
        triggered.append(f"large scope ({len(changed)} files changed)")

    # Heuristic: new directories
    dirs_seen = set()
    for f in changed:
        parts = f.split("/")
        if len(parts) >= 2:
            dirs_seen.add(parts[0])
    notable_new_dirs = [d for d in dirs_seen if d not in ("src", "test", "tests", "lib", "dist", "build", ".")]
    if len(notable_new_dirs) >= 2:
        triggered.append(f"new directories ({', '.join(sorted(notable_new_dirs)[:4])})")

    # Pattern-based heuristics
    for h in CONTEXT_DRIFT_HEURISTICS:
        for pattern in h["patterns"]:
            if any(pattern in f for f in changed):
                triggered.append(h["label"])
                break

    return triggered


def main():
    project_dir = os.environ.get("CURSOR_WORKSPACE_PATH", os.getcwd())
    os.chdir(project_dir)
    config_dir = ".cursor"

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
    changed_files_raw = run("git diff --name-only HEAD 2>/dev/null")
    if changed_files_raw:
        for fname in changed_files_raw.split("\n"):
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

    # Detect context drift requiring AGENTS.md update
    drift_triggers = detect_context_drift(changed_files_raw)
    if drift_triggers:
        triggered_list = "\n  - ".join(drift_triggers)
        print(
            f"\nNOTE: This session made significant changes:\n  - {triggered_list}\n"
            "Your AGENTS.md may be outdated. Consider running the project-setup skill to regenerate it,\n"
            "or manually update the Architecture / Tech Stack / Conventions sections.",
            file=sys.stderr,
        )

    # Emit handoff suggestion
    print(
        "\nTip: Before closing, add a brief summary of decisions made and next steps to .cursor/session-notes.md",
        file=sys.stderr,
    )

    # Build structured session summary
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    recent_commits = run("git log --oneline -3 2>/dev/null") or "No commits"
    branch = run("git branch --show-current 2>/dev/null") or "unknown"

    changed_files_list = ""
    if changed_files_raw:
        files = [f.strip() for f in changed_files_raw.split("\n") if f.strip()]
        changed_files_list = "\n".join(f"  {f}" for f in files[:10])
        if len(files) > 10:
            changed_files_list += f"\n  ... and {len(files) - 10} more"

    active_plans = list_active_plans(project_dir, config_dir)
    plans_str = ", ".join(active_plans) if active_plans else "none"

    token_pct = read_last_token_usage(project_dir, config_dir)
    token_str = f"{token_pct:.0f}%" if token_pct is not None else "unknown"

    summary = f"""## Session {timestamp}

Branch: {branch}
Recent commits:
{recent_commits}

Uncommitted changes: {git_status if git_status else 'none'}

Modified files:
{changed_files_list if changed_files_list else '  none'}

Active plans: {plans_str}
Token usage (last): {token_str}

<!-- Add decisions, discoveries, and next steps below -->

---
"""

    notes_path = os.path.join(project_dir, config_dir, "session-notes.md")
    os.makedirs(os.path.dirname(notes_path), exist_ok=True)

    existing = ""
    if os.path.exists(notes_path):
        with open(notes_path) as f:
            existing = f.read()

    with open(notes_path, "w") as f:
        f.write(summary + existing)

    # Append structured entry to daily-updates.jsonl for automated standup
    append_daily_update_entry(project_dir, config_dir, recent_commits, changed_files_raw)

    sys.exit(0)


def _read_last_logged_commits(jsonl_path):
    """Read commit hashes from the most recent JSONL entry to avoid duplicates."""
    if not os.path.exists(jsonl_path):
        return set()
    try:
        with open(jsonl_path, encoding="utf-8") as f:
            lines = [l.strip() for l in f if l.strip()]
        if not lines:
            return set()
        last = json.loads(lines[-1])
        return set(last.get("commits", []))
    except Exception:
        return set()


def append_daily_update_entry(project_dir, config_dir, recent_commits_raw, changed_files_raw):
    """Append a structured accomplishment entry to daily-updates.jsonl."""
    try:
        jsonl_path = os.path.join(project_dir, config_dir, "daily-updates.jsonl")

        previously_logged = _read_last_logged_commits(jsonl_path)

        commits = []
        commit_summary_parts = []
        if recent_commits_raw and recent_commits_raw != "No commits":
            for line in recent_commits_raw.splitlines():
                line = line.strip()
                if not line:
                    continue
                parts = line.split(" ", 1)
                if len(parts) == 2:
                    sha = parts[0]
                    if sha not in previously_logged:
                        commits.append(sha)
                        commit_summary_parts.append(parts[1])

        files_changed = 0
        if changed_files_raw:
            files_changed = len([f for f in changed_files_raw.splitlines() if f.strip()])

        if not commits and files_changed == 0:
            return

        summary = "; ".join(commit_summary_parts) if commit_summary_parts else f"{files_changed} file(s) modified"

        entry = {
            "ts": datetime.now(tz=timezone.utc).isoformat(timespec="seconds"),
            "project": project_dir,
            "summary": summary,
            "commits": commits,
            "files_changed": files_changed,
        }

        os.makedirs(os.path.dirname(jsonl_path), exist_ok=True)
        with open(jsonl_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")
    except Exception:
        pass


if __name__ == "__main__":
    main()
