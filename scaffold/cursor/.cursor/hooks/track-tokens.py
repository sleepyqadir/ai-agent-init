#!/usr/bin/env python3
"""
Token Usage Tracker (afterAgentResponse / stop event)
Appends a JSONL record to .cursor/token-usage.jsonl in the project directory.
Non-blocking — always exits 0.
"""

import json
import os
import sys
from datetime import datetime, timezone

LOG_FILENAME = os.path.join(".cursor", "token-usage.jsonl")


def extract_model(payload):
    model = payload.get("model")
    if isinstance(model, dict):
        return model.get("id"), model.get("display_name")
    if isinstance(model, str):
        return model, None
    return None, None


def extract_context_window(payload):
    ctx = payload.get("context_window")
    if not ctx or not isinstance(ctx, dict):
        return None
    result = {
        "input_tokens": ctx.get("total_input_tokens"),
        "output_tokens": ctx.get("total_output_tokens"),
        "window_size": ctx.get("context_window_size"),
        "used_pct": ctx.get("used_percentage"),
    }
    return {k: v for k, v in result.items() if v is not None} or None


def main():
    try:
        payload = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, EOFError, ValueError):
        payload = {}

    project_dir = os.environ.get("CURSOR_WORKSPACE_PATH", os.getcwd())
    log_path = os.path.join(project_dir, LOG_FILENAME)

    os.makedirs(os.path.dirname(log_path), exist_ok=True)

    model_id, model_display = extract_model(payload)
    ctx = extract_context_window(payload)

    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "project": os.path.basename(project_dir),
        "project_path": project_dir,
    }

    if payload.get("session_id"):
        record["session_id"] = payload["session_id"]
    if model_id:
        record["model"] = model_id
    if model_display:
        record["model_display"] = model_display
    if ctx:
        record["context_window"] = ctx

    record["raw_keys"] = list(payload.keys())

    try:
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")
    except OSError:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
