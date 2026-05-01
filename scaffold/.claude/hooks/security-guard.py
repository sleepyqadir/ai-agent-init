#!/usr/bin/env python3
"""
Security Guard Hook (PreToolUse: Edit, Write, MultiEdit)
Scans file content for 15 dangerous patterns before allowing writes.
Blocks on first new occurrence per file per session (exit code 2).
Warns on subsequent occurrences (exit code 0 with message).
"""

import json
import os
import re
import sys
import tempfile

PATTERNS = [
    # Injection risks
    {
        "id": "eval_injection",
        "name": "Code Injection via eval()",
        "regex": r"\beval\s*\(",
        "extensions": ["js", "ts", "jsx", "tsx", "py"],
        "message": "eval() executes arbitrary strings as code. Never use with user-controlled input. Use a safer alternative.",
    },
    {
        "id": "new_function_injection",
        "name": "Code Injection via new Function()",
        "regex": r"\bnew\s+Function\s*\(",
        "extensions": ["js", "ts", "jsx", "tsx"],
        "message": "new Function() constructs code from strings. Enables injection attacks. Avoid dynamic code generation.",
    },
    {
        "id": "exec_injection",
        "name": "Command Injection via exec()",
        "regex": r"\bexec\s*\(",
        "extensions": ["js", "ts", "jsx", "tsx"],
        "message": "child_process.exec() passes commands to the shell. Use execFile() with argument arrays to prevent injection.",
    },
    {
        "id": "os_system_injection",
        "name": "Command Injection via os.system()",
        "regex": r"\bos\.system\s*\(",
        "extensions": ["py"],
        "message": "os.system() invokes the shell. Use subprocess.run() with a list of arguments instead.",
    },
    {
        "id": "pickle_deserialization",
        "name": "Arbitrary Code via pickle.loads()",
        "regex": r"\bpickle\.loads?\s*\(",
        "extensions": ["py"],
        "message": "pickle.loads() can execute arbitrary code during deserialization. Use JSON or a safe serialization format.",
    },
    # XSS risks
    {
        "id": "dangerous_inner_html",
        "name": "XSS via dangerouslySetInnerHTML",
        "regex": r"dangerouslySetInnerHTML",
        "extensions": ["jsx", "tsx"],
        "message": "dangerouslySetInnerHTML bypasses React's XSS protection. Sanitize with DOMPurify before using.",
    },
    {
        "id": "inner_html_assignment",
        "name": "XSS via innerHTML assignment",
        "regex": r"\.innerHTML\s*=",
        "extensions": ["js", "ts", "jsx", "tsx"],
        "message": "innerHTML assignment can execute injected scripts. Use textContent for text, or sanitize HTML with DOMPurify.",
    },
    {
        "id": "document_write_xss",
        "name": "XSS via document.write()",
        "regex": r"\bdocument\.write\s*\(",
        "extensions": ["js", "ts", "jsx", "tsx"],
        "message": "document.write() can inject malicious HTML. Use DOM APIs (createElement, appendChild) instead.",
    },
    # Hardcoded secrets
    {
        "id": "hardcoded_api_key",
        "name": "Hardcoded API Key",
        "regex": r"(?i)(api_key|apikey|api-key)\s*[=:]\s*['\"][a-zA-Z0-9_\-]{16,}['\"]",
        "extensions": ["js", "ts", "jsx", "tsx", "py", "json", "yaml", "yml", "env"],
        "message": "API key appears hardcoded. Use environment variables: process.env.API_KEY or os.environ['API_KEY'].",
    },
    {
        "id": "hardcoded_secret",
        "name": "Hardcoded Secret or Password",
        "regex": r"(?i)(secret|password|passwd|token)\s*[=:]\s*['\"][^'\"]{8,}['\"]",
        "extensions": ["js", "ts", "jsx", "tsx", "py", "json"],
        "message": "Secret or password appears hardcoded. Move to environment variables immediately.",
    },
    # SQL injection
    {
        "id": "sql_concatenation",
        "name": "SQL Injection via String Concatenation",
        "regex": r"(SELECT|INSERT|UPDATE|DELETE|WHERE).*['\"\`]\s*\+|\".*SELECT.*\"\s*\+",
        "extensions": ["js", "ts", "jsx", "tsx", "py"],
        "message": "SQL built via string concatenation enables injection. Use parameterized queries or an ORM.",
    },
    # GitHub Actions injection
    {
        "id": "github_actions_injection",
        "name": "GitHub Actions Expression Injection",
        "regex": r"\$\{\{.*github\.event\.(issue|pull_request|comment|head_commit)",
        "extensions": ["yml", "yaml"],
        "message": "User-controlled GitHub event data in a run: block enables command injection. Use an intermediate env var.",
    },
    # Insecure randomness
    {
        "id": "insecure_random",
        "name": "Insecure Randomness for Security Context",
        "regex": r"Math\.random\s*\(\)",
        "extensions": ["js", "ts", "jsx", "tsx"],
        "message": "Math.random() is not cryptographically secure. Use crypto.randomBytes() or crypto.randomUUID() for tokens and secrets.",
    },
    # Weak JWT
    {
        "id": "weak_jwt_none",
        "name": "Weak JWT Algorithm (none)",
        "regex": r"algorithm['\"]?\s*[=:]\s*['\"]none['\"]",
        "extensions": ["js", "ts", "jsx", "tsx", "py"],
        "message": "JWT algorithm 'none' disables signature verification. Always use RS256 or HS256 with a strong secret.",
    },
]


def get_state_file(session_id):
    safe_id = re.sub(r"[^a-zA-Z0-9_.-]", "_", session_id or "default")
    return os.path.join(tempfile.gettempdir(), f"security_guard_{safe_id}.json")


def load_state(session_id):
    path = get_state_file(session_id)
    if os.path.exists(path):
        try:
            with open(path) as f:
                return json.load(f)
        except Exception:
            return {}
    return {}


def save_state(state, session_id):
    with open(get_state_file(session_id), "w") as f:
        json.dump(state, f)


def get_extension(file_path):
    return os.path.splitext(file_path)[1].lstrip(".").lower()


def check(content, file_path):
    ext = get_extension(file_path)
    matches = []
    for p in PATTERNS:
        if ext not in p["extensions"]:
            continue
        if re.search(p["regex"], content, re.MULTILINE):
            matches.append(p)
    return matches


def collect_content(tool_input):
    parts = []
    if tool_input.get("content"):
        parts.append(tool_input["content"])
    if tool_input.get("new_string"):
        parts.append(tool_input["new_string"])
    for edit in tool_input.get("edits", []):
        if isinstance(edit, dict) and edit.get("new_string"):
            parts.append(edit["new_string"])
    return "\n".join(parts)


def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    session_id = hook_input.get("session_id", "default")
    tool_input = hook_input.get("tool_input", {})
    file_path = tool_input.get("file_path", "")
    content = collect_content(tool_input)

    if not file_path or not content:
        sys.exit(0)

    matches = check(content, file_path)
    if not matches:
        sys.exit(0)

    state = load_state(session_id)
    new_warnings = []

    for m in matches:
        key = f"{file_path}:{m['id']}"
        if key not in state:
            state[key] = True
            new_warnings.append(m)

    if not new_warnings:
        sys.exit(0)

    save_state(state, session_id)

    lines = [f"Security warning in {file_path}:"]
    for w in new_warnings:
        lines.append(f"\n[{w['name']}]")
        lines.append(w["message"])

    print("\n".join(lines), file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()
