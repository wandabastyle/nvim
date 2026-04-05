#!/usr/bin/env python3

import json
import subprocess
import sys
import time
import urllib.request

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
OLLAMA_TAGS_URL = "http://127.0.0.1:11434/api/tags"
MODEL = "qwen2.5-coder:7b"
MAX_DIFF_CHARS = 12000
SUBMODULE_LOG_COUNT = 5


def run(cmd):
    """
    Run a command and return stripped stdout.

    Return None if the command fails.
    """
    result = subprocess.run(
        cmd,
        text=True,
        capture_output=True,
    )

    if result.returncode != 0:
        return None

    return result.stdout.strip()


def get_diff():
    """
    Return the best available git diff.

    We prefer the staged diff because that is usually closer to what will
    become the next commit.

    Return a tuple:
        (diff_kind, diff_text)

    where diff_kind is:
        "staged"    -> git diff --cached
        "working"   -> git diff

    Return (None, None) if there is no diff.
    """
    staged = run([
        "git",
        "diff",
        "--cached",
        "--no-ext-diff",
        "--unified=0",
    ])

    if staged:
        return "staged", staged

    working = run([
        "git",
        "diff",
        "--no-ext-diff",
        "--unified=0",
    ])

    if working:
        return "working", working

    return None, None


def get_changed_files():
    """
    Return a short git status listing.

    This is useful context for the LLM because filenames often make the
    intent of a change much clearer.
    """
    status = run([
        "git",
        "status",
        "--short",
    ])

    if not status:
        return ""

    return status


def get_submodule_logs():
    """
    Return short commit logs for changed submodules.

    The main repo diff only shows submodule pointer changes. These short
    logs give the model actual context from inside the submodule repos.
    """
    status = run([
        "git",
        "submodule",
        "status",
    ])

    if not status:
        return ""

    logs = []

    for line in status.splitlines():
        line = line.strip()

        # Changed submodules are marked with '+' or '-'.
        if not line or line[0] not in "+-":
            continue

        parts = line.split()

        if len(parts) < 2:
            continue

        path = parts[1]

        log = run([
            "git",
            "-C",
            path,
            "log",
            "--oneline",
            "-n",
            str(SUBMODULE_LOG_COUNT),
        ])

        if not log:
            continue

        logs.append(
            f"{path}:\n{log}"
        )

    if not logs:
        return ""

    return "\n\n".join(logs)


def ollama_ping():
    """
    Return True if the local Ollama server is responding.
    """
    try:
        request = urllib.request.Request(OLLAMA_TAGS_URL)

        with urllib.request.urlopen(request, timeout=1.2) as response:
            return response.status == 200

    except Exception:
        return False


def ensure_ollama():
    """
    Ensure Ollama is running through the user systemd service.

    We also restart the stop timer so each use refreshes the TTL.
    """
    if not ollama_ping():
        result = subprocess.run(
            [
                "systemctl",
                "--user",
                "start",
                "ollama.service",
            ],
            text=True,
            capture_output=True,
        )

        if result.returncode != 0:
            raise RuntimeError(
                "Failed to start ollama.service:\n"
                + (result.stderr.strip() or "unknown error")
            )

        for _ in range(25):
            if ollama_ping():
                break

            time.sleep(0.2)

        if not ollama_ping():
            raise RuntimeError(
                "Ollama server did not come up"
            )

    timer_result = subprocess.run(
        [
            "systemctl",
            "--user",
            "restart",
            "ollama-stop.timer",
        ],
        text=True,
        capture_output=True,
    )

    if timer_result.returncode != 0:
        raise RuntimeError(
            "Failed to restart ollama-stop.timer:\n"
            + (timer_result.stderr.strip() or "unknown error")
        )


def ask_ollama(diff_kind, changed_files, diff_text, submodule_logs):
    """
    Ask Ollama for a single commit message suggestion.

    We keep the prompt strict so the model returns one short subject line,
    not an explanation or a full commit body.
    """
    trimmed_diff = diff_text[:MAX_DIFF_CHARS]

    prompt = f"""You write excellent git commit messages.

Task:
Generate exactly one git commit message for this {diff_kind} diff.

Rules:
- Output only the commit message
- No quotes
- One line only
- Use conventional commits
- Keep it under 72 characters if possible
- Be specific, not generic

Changed files:
{changed_files or "(none)"}

Submodule changes:
{submodule_logs or "(none)"}

Diff:
{trimmed_diff}
"""

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "stream": False,
        "keep_alive": "10m",
    }

    request = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=80) as response:
        data = json.load(response)

    text = data.get("response", "").strip()

    if not text:
        return None

    first_line = text.splitlines()[0].strip()
    first_line = first_line.strip("`").strip()

    return first_line


def main():
    """Script entry point."""
    inside = run([
        "git",
        "rev-parse",
        "--is-inside-work-tree",
    ])

    if inside != "true":
        # Quiet exit is best when this is triggered from Neovim.
        return 0

    diff_kind, diff_text = get_diff()

    if not diff_text:
        return 0

    changed_files = get_changed_files()
    submodule_logs = get_submodule_logs()

    ensure_ollama()

    message = ask_ollama(
        diff_kind,
        changed_files,
        diff_text,
        submodule_logs,
    )

    if not message:
        return 0

    print(message)

    return 0


if __name__ == "__main__":
    sys.exit(main())
