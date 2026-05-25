#!/usr/bin/env python3
"""
daily-update-send.py — Automated daily standup generator and Slack DM sender.

Usage:
  python3 daily-update-send.py           # send update for current directory
  python3 daily-update-send.py --dry-run # preview without sending

Config: ~/.aiagent-init/config.json
Setup:  aiagent-init --setup-daily-update
"""

import json
import os
import ssl
import subprocess
import sys
import urllib.request
import urllib.error
from datetime import datetime, timedelta, timezone

CONFIG_PATH = os.path.join(os.path.expanduser("~"), ".aiagent-init", "config.json")
SLACK_API_URL = "https://slack.com/api/chat.postMessage"
OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

# Most cost-effective models per provider for this small summarisation task
DEFAULT_MODELS = {
    "openai": "gpt-4o-mini",           # $0.15 / $0.60 per M tokens
    "anthropic": "claude-3-haiku-20240307",  # $0.25 / $1.25 per M tokens
}

SYNTHESIS_PROMPT = """You are generating the "Done:" section of a daily standup update from structured session data.

Rules:
- Output ONLY the Done bullet points — no section header, no Todo, no preamble, no sign-off
- 3-7 concise bullet points maximum, each starting with •
- Each bullet is one sentence, plain language, outcome-first
- Group related items into a single bullet
- Skip trivial changes (typos, formatting, version bumps)
- Style: direct and factual. Examples:
  Good: "• Tier-based subscription system with per-endpoint usage tracking and rate-limit guards"
  Good: "• Fix creation timestamp issue in trades"
  Bad: "• Worked on various improvements"

Output only the bullet lines, nothing else."""


# ── SSL context ────────────────────────────────────────────────────────────────
# macOS Python.org installs don't load system certs automatically.
# Build an SSL context that works across macOS and Linux without pip deps.
def _build_ssl_context():
    ctx = ssl.create_default_context()
    ca_paths = [
        "/etc/ssl/cert.pem",                      # macOS / FreeBSD
        "/etc/ssl/certs/ca-certificates.crt",     # Ubuntu / Debian
        "/etc/pki/tls/certs/ca-bundle.crt",       # RHEL / CentOS
        "/etc/ssl/ca-bundle.pem",                 # openSUSE
    ]
    for path in ca_paths:
        if os.path.isfile(path):
            try:
                ctx.load_verify_locations(cafile=path)
                return ctx
            except ssl.SSLError:
                continue
    try:
        import certifi  # type: ignore
        ctx.load_verify_locations(cafile=certifi.where())
    except ImportError:
        pass
    return ctx


_SSL_CTX = _build_ssl_context()


# ── Config ─────────────────────────────────────────────────────────────────────
def load_config():
    if not os.path.exists(CONFIG_PATH):
        print(f"Error: config not found at {CONFIG_PATH}", file=sys.stderr)
        print("Run: aiagent-init --setup-daily-update", file=sys.stderr)
        sys.exit(1)
    with open(CONFIG_PATH, encoding="utf-8") as f:
        return json.load(f)


# ── Data collection ────────────────────────────────────────────────────────────
def collect_entries(projects, hours=24):
    """Collect daily-update JSONL entries from all projects within the last N hours."""
    cutoff = datetime.now(tz=timezone.utc) - timedelta(hours=hours)
    entries = []
    config_dirs = [".cursor", ".claude"]

    for project in projects:
        if not os.path.isdir(project):
            continue
        for config_dir in config_dirs:
            jsonl_path = os.path.join(project, config_dir, "daily-updates.jsonl")
            if not os.path.exists(jsonl_path):
                continue
            try:
                with open(jsonl_path, encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            entry = json.loads(line)
                            ts_str = entry.get("ts", "")
                            try:
                                ts = datetime.fromisoformat(ts_str)
                                if ts.tzinfo is None:
                                    ts = ts.replace(tzinfo=timezone.utc)
                            except ValueError:
                                continue
                            if ts >= cutoff:
                                entries.append(entry)
                        except json.JSONDecodeError:
                            continue
            except OSError:
                continue

    return entries


def collect_git_commits(projects, hours=24):
    """Fallback: read git commits from the last N hours across all projects."""
    since = f"{hours} hours ago"
    entries = []

    for project in projects:
        if not os.path.isdir(project):
            continue
        try:
            result = subprocess.run(
                ["git", "log", f"--since={since}", "--oneline", "--no-merges"],
                cwd=project,
                capture_output=True,
                text=True,
                timeout=10,
            )
            lines = [l.strip() for l in result.stdout.splitlines() if l.strip()]
            if not lines:
                continue
            commits = []
            summaries = []
            for line in lines:
                parts = line.split(" ", 1)
                if len(parts) == 2:
                    commits.append(parts[0])
                    summaries.append(parts[1])
            entries.append({
                "ts": datetime.now(tz=timezone.utc).isoformat(timespec="seconds"),
                "project": project,
                "summary": "; ".join(summaries),
                "commits": commits,
                "files_changed": 0,
                "source": "git",
            })
        except Exception:
            continue

    return entries


# ── Formatting ─────────────────────────────────────────────────────────────────
def build_date_header(hours=24):
    """Build the date header line, e.g.: Date: 2026-05-25 (last 24 hrs, since 2026-05-24 12:34)"""
    now = datetime.now()
    since = now - timedelta(hours=hours)
    return (
        f"Date: {now.strftime('%Y-%m-%d')} "
        f"(last {hours} hrs, since {since.strftime('%Y-%m-%d %H:%M')})"
    )


def build_raw_bullets(entries):
    """Build plain bullet list from entries (fallback when LLM is unavailable)."""
    seen = set()
    bullets = []
    for entry in entries:
        summary = entry.get("summary", "").strip()
        if summary and summary not in seen:
            seen.add(summary)
            bullets.append(f"• {summary}")
    return "\n".join(bullets) if bullets else None


def format_message(done_bullets, date_header):
    """Assemble the full standup message with Done / Todo / Roadblock sections."""
    return (
        f"{date_header}\n\n"
        f"Done:\n{done_bullets}\n\n"
        f"Todo:\nadd yourself\n\n"
        f"Roadblock:\nadd yourself"
    )


# ── LLM synthesis ──────────────────────────────────────────────────────────────
def call_openai(api_key, model, entries_text):
    payload = {
        "model": model,
        "max_tokens": 400,
        "messages": [
            {"role": "system", "content": SYNTHESIS_PROMPT},
            {"role": "user", "content": entries_text},
        ],
    }
    req = urllib.request.Request(
        OPENAI_API_URL,
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, context=_SSL_CTX, timeout=30) as resp:
        data = json.loads(resp.read())
    return data["choices"][0]["message"]["content"].strip()


def call_anthropic(api_key, model, entries_text):
    payload = {
        "model": model,
        "max_tokens": 400,
        "system": SYNTHESIS_PROMPT,
        "messages": [{"role": "user", "content": entries_text}],
    }
    req = urllib.request.Request(
        ANTHROPIC_API_URL,
        data=json.dumps(payload).encode(),
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, context=_SSL_CTX, timeout=30) as resp:
        data = json.loads(resp.read())
    return data["content"][0]["text"].strip()


def synthesize_with_llm(cfg, entries):
    """Call the configured LLM to produce Done bullet points."""
    provider = cfg.get("llm_provider", "openai").lower()
    api_key = cfg.get("llm_api_key", "")
    model = cfg.get("llm_model") or DEFAULT_MODELS.get(provider, "gpt-4o-mini")

    if not api_key:
        return None

    input_lines = []
    for i, entry in enumerate(entries, 1):
        project_name = os.path.basename(entry.get("project", "unknown"))
        input_lines.append(f"Session {i} [{project_name}]: {entry.get('summary', '')}")
        commits = entry.get("commits", [])
        if commits:
            input_lines.append(f"  Commits: {', '.join(commits[:5])}")

    entries_text = "\n".join(input_lines)

    try:
        if provider == "openai":
            return call_openai(api_key, model, entries_text)
        elif provider == "anthropic":
            return call_anthropic(api_key, model, entries_text)
        else:
            print(f"Warning: unknown LLM provider '{provider}', using raw bullets", file=sys.stderr)
            return None
    except urllib.error.HTTPError as e:
        print(f"Warning: LLM API error {e.code} — falling back to raw bullets", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Warning: LLM call failed ({e}) — falling back to raw bullets", file=sys.stderr)
        return None


# ── Slack ──────────────────────────────────────────────────────────────────────
def post_slack_dm(bot_token, user_id, message):
    """Post a direct message to a Slack user via chat.postMessage."""
    payload = {
        "channel": user_id,
        "text": message,
        "mrkdwn": True,
    }
    req = urllib.request.Request(
        SLACK_API_URL,
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {bot_token}",
            "Content-Type": "application/json; charset=utf-8",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, context=_SSL_CTX, timeout=15) as resp:
        data = json.loads(resp.read())

    if not data.get("ok"):
        raise RuntimeError(f"Slack API error: {data.get('error', 'unknown')}")


# ── Main ───────────────────────────────────────────────────────────────────────
def main():
    dry_run = "--dry-run" in sys.argv

    config = load_config()
    du_cfg = config.get("daily_update", {})

    if not du_cfg.get("enabled", True):
        print("Daily update is disabled. Run: aiagent-init --setup-daily-update to re-enable.")
        sys.exit(0)

    bot_token = du_cfg.get("slack_bot_token", "")
    user_id = du_cfg.get("slack_user_id", "")
    projects = du_cfg.get("projects", [])

    if not bot_token or not user_id:
        print("Error: Slack credentials not configured.", file=sys.stderr)
        print("Run: aiagent-init --setup-daily-update", file=sys.stderr)
        sys.exit(1)

    if not projects:
        projects = [os.getcwd()]

    print(f"Collecting sessions from last 24h across {len(projects)} project(s)...")
    entries = collect_entries(projects)

    if not entries:
        print("No session entries found — falling back to git commits...")
        entries = collect_git_commits(projects)

    if not entries:
        print("No session activity or git commits found in the last 24 hours. Nothing to send.")
        sys.exit(0)

    source = "git commits" if entries and entries[0].get("source") == "git" else "session entries"
    print(f"Found {len(entries)} {source}. Synthesizing with LLM...")

    done_bullets = synthesize_with_llm(du_cfg, entries)
    if not done_bullets:
        print("LLM unavailable — using raw bullets.")
        done_bullets = build_raw_bullets(entries)

    if not done_bullets:
        print("No content to send.")
        sys.exit(0)

    date_header = build_date_header()
    message = format_message(done_bullets, date_header)

    print("\n--- Update Preview ---")
    print(message)
    print("----------------------\n")

    if dry_run:
        print("[dry-run] Not sending to Slack.")
        sys.exit(0)

    print("Sending to Slack...")
    try:
        post_slack_dm(bot_token, user_id, message)
        print("Daily update sent successfully.")
    except urllib.error.HTTPError as e:
        print(f"Error: Slack HTTP {e.code}", file=sys.stderr)
        sys.exit(1)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
