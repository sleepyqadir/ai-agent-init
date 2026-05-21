#!/usr/bin/env python3
"""
Bash Guard Hook (beforeShellExecution event)
Scans shell commands for dangerous patterns before allowing execution.
Always blocks matching commands (exit code 2). No session-state exceptions.

Cursor's beforeShellExecution delivers stdin JSON with a top-level "command" field.
"""

import json
import re
import sys

PATTERNS = [
    # Secret file access via shell
    {
        "id": "cat_env",
        "name": "Secret file read via shell",
        "regex": r"\b(cat|head|tail|less|more|bat)\s+.*\.env\b",
        "message": "Reading .env files via shell bypasses permission controls. Use the Read tool or environment variables directly.",
    },
    {
        "id": "grep_env",
        "name": "Secret file search via shell",
        "regex": r"\b(grep|ag|rg|ack)\s+.*\.env\b",
        "message": "Searching .env files via shell bypasses permission controls.",
    },
    {
        "id": "cat_secrets",
        "name": "Secret directory read via shell",
        "regex": r"\b(cat|head|tail|less|more)\s+.*(secret|credential|private.key)",
        "message": "Reading secret/credential files via shell. Use environment variables instead.",
    },
    # Printing environment secrets
    {
        "id": "echo_secret_env",
        "name": "Printing secret environment variables",
        "regex": r"(?i)(echo|printf|printenv)\s+.*\$\{?(SECRET|API_KEY|TOKEN|PASSWORD|CREDENTIAL|PRIVATE_KEY)",
        "message": "Printing secret environment variables to stdout. Secrets should never appear in command output.",
    },
    # Dangerous downloads piped to shell
    # Exempts trusted raw.githubusercontent.com and github.com installer URLs
    {
        "id": "curl_pipe_bash",
        "name": "Piping download to shell",
        "regex": r"(curl|wget)\s+(?!.*raw\.githubusercontent\.com)(?!.*github\.com).*\|\s*(bash|sh|zsh|sudo)",
        "message": "Piping downloads directly to shell executes unreviewed code. Download first, review, then execute.",
    },
    # Dangerous permissions
    {
        "id": "chmod_777",
        "name": "World-writable permissions",
        "regex": r"chmod\s+(-R\s+)?777\b|chmod\s+(-R\s+)?a\+rwx",
        "message": "chmod 777 makes files world-readable, writable, and executable. Use specific permissions instead.",
    },
    # Destructive database commands
    {
        "id": "drop_database",
        "name": "Destructive database operation",
        "regex": r"(?i)\b(drop\s+(database|table|schema)|truncate\s+table)",
        "message": "Destructive database operation detected. Confirm backup exists and user has approved this action.",
    },
    # Dangerous infrastructure commands
    {
        "id": "terraform_destroy",
        "name": "Infrastructure destruction",
        "regex": r"\b(terraform\s+destroy|pulumi\s+destroy)",
        "message": "Infrastructure destroy detected. This is irreversible. Confirm environment and user approval.",
    },
    {
        "id": "kubectl_delete",
        "name": "Kubernetes resource deletion",
        "regex": r"\bkubectl\s+delete\s+",
        "message": "Kubernetes resource deletion detected. Confirm the correct cluster/namespace and user approval.",
    },
    {
        "id": "docker_prune",
        "name": "Docker system prune",
        "regex": r"\bdocker\s+system\s+prune\s+-a",
        "message": "Docker system prune -a removes all unused images, containers, and volumes. Confirm this is intended.",
    },
    # Full environment dump
    {
        "id": "dump_environment",
        "name": "Environment variable dump",
        "regex": r"(?:^|\s)(env|printenv|set|export\s+-p)\s*$",
        "message": "Dumping the full environment can expose secrets. Print only specific non-sensitive variables.",
    },
    # Broad git staging
    {
        "id": "git_add_all",
        "name": "Broad git staging",
        "regex": r"\bgit\s+add\s+(-A|--all|\.\s*$)",
        "message": "git add . / git add -A stages all files including unintended ones. Stage files explicitly by name.",
    },
    # Fork bomb
    {
        "id": "fork_bomb",
        "name": "Fork bomb pattern",
        "regex": r":\(\)\{\s*:\|:&\s*\};:",
        "message": "Fork bomb detected. This will crash the system.",
    },
]

SAFE_ENV_FILES = {".env.example", ".env.sample", ".env.template"}


def has_unsafe_env_file(command):
    """Check if a command references any .env file that is NOT a safe template."""
    env_paths = re.findall(r"(?:^|\s)([^\s'\";|&]*\.env(?:\.[^\s'\";|&]+)?)", command)
    if not env_paths:
        return True
    for path in env_paths:
        name = path.strip("'\"").split("/")[-1]
        if name not in SAFE_ENV_FILES:
            return True
    return False


def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    # Cursor beforeShellExecution delivers "command" at the top level
    command = hook_input.get("command", "")

    # Fallback: some versions nest it in tool_input
    if not command:
        command = hook_input.get("tool_input", {}).get("command", "")

    if not command:
        sys.exit(0)

    matches = []
    for p in PATTERNS:
        if re.search(p["regex"], command, re.MULTILINE):
            if p["id"] in ("cat_env", "grep_env"):
                if not has_unsafe_env_file(command):
                    continue
            matches.append(p)

    if not matches:
        sys.exit(0)

    lines = ["Bash security block:"]
    for m in matches:
        lines.append(f"\n[{m['name']}]")
        lines.append(m["message"])
        lines.append(f"Command: {command[:200]}")

    print("\n".join(lines), file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()
