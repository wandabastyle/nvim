#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import time
import urllib.request
from collections.abc import Sequence
from http.client import HTTPResponse
from typing import Literal, cast

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
OLLAMA_TAGS_URL = "http://127.0.0.1:11434/api/tags"
MODEL = "qwen2.5-coder:7b"
MAX_DIFF_CHARS = 12000
SUBMODULE_LOG_COUNT = 5
DEFAULT_PR_BASE = "origin/main"


def run(cmd: Sequence[str]) -> str | None:
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


def get_diff() -> tuple[Literal["staged", "working"] | None, str | None]:
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


def get_changed_files() -> str:
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


def get_submodule_logs() -> str:
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

    logs: list[str] = []

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


def get_pr_diff(base_ref: str) -> str | None:
    """Return the PR diff for a base ref, or None."""
    pr_diff = run([
        "git",
        "diff",
        "--no-ext-diff",
        "--unified=0",
        f"{base_ref}...HEAD",
    ])

    if not pr_diff:
        return None

    return pr_diff


def get_pr_changed_files(base_ref: str) -> str:
    """Return a changed-files list for a PR range."""
    changed = run([
        "git",
        "diff",
        "--name-status",
        f"{base_ref}...HEAD",
    ])

    if not changed:
        return ""

    return changed


def get_pr_commits(base_ref: str) -> str:
    """Return short commit log for commits in the PR range."""
    commits = run([
        "git",
        "log",
        "--oneline",
        f"{base_ref}..HEAD",
    ])

    if not commits:
        return ""

    return commits


def parse_args(argv: Sequence[str]) -> tuple[Literal["commit", "pr_title", "pr_body"], str | None] | None:
    """Parse CLI flags and return (mode, base_ref)."""
    mode: Literal["commit", "pr_title", "pr_body"] = "commit"
    base_ref: str | None = None
    index = 0

    while index < len(argv):
        arg = argv[index]

        if arg == "--pr-title":
            if mode != "commit":
                return None

            mode = "pr_title"
            index += 1
            continue

        if arg == "--pr-body":
            if mode != "commit":
                return None

            mode = "pr_body"
            index += 1
            continue

        if arg == "--base":
            if index + 1 >= len(argv):
                return None

            base_ref = argv[index + 1].strip() or None
            index += 2
            continue

        if arg.startswith("--base="):
            base_ref = arg.split("=", 1)[1].strip() or None
            index += 1
            continue

        return None

    return mode, base_ref


def resolve_pr_base(cli_base_ref: str | None) -> str:
    """Resolve PR base from CLI, env, then default."""
    if cli_base_ref:
        return cli_base_ref

    env_base_ref = os.environ.get("GIT_PR_BASE", "").strip()

    if env_base_ref:
        return env_base_ref

    return DEFAULT_PR_BASE


def ollama_ping() -> bool:
    """
    Return True if the local Ollama server is responding.
    """
    try:
        request = urllib.request.Request(OLLAMA_TAGS_URL)

        with cast(HTTPResponse, urllib.request.urlopen(request, timeout=1.2)):
            return True

    except Exception:
        return False


def ensure_ollama() -> None:
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


def ask_ollama(
    diff_kind: Literal["staged", "working"],
    changed_files: str,
    diff_text: str,
    submodule_logs: str,
) -> str | None:
    """
    Ask Ollama for a single commit message suggestion.

    We keep the prompt strict so the model returns one short subject line,
    not an explanation or a full commit body.
    """
    trimmed_diff = diff_text[:MAX_DIFF_CHARS]

    prompt = f"""You write excellent git commit messages.

Task:
Generate exactly one git commit subject for this {diff_kind} diff.

## Commits
- Use conventional-style commit subjects:
  - fix(...)
  - feat(...)
  - chore(...)
  - docs(...)
  - refactor(...)
  - test(...)
- Use format: type(scope): subject
  - scope is optional, so type: subject is valid
- Keep commits scoped: do not mix unrelated changes in the message
- Never include secrets in the message (tokens, credentials, .env values)

Output rules:
- Output only the commit subject
- No quotes
- One line only
- Keep it under 72 characters if possible
- Be specific, not generic

Changed files:
{changed_files or "(none)"}

Submodule changes:
{submodule_logs or "(none)"}

Diff:
{trimmed_diff}
"""

    payload: dict[str, object] = {
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

    with cast(HTTPResponse, urllib.request.urlopen(request, timeout=80)) as response:
        body = response.read().decode("utf-8")

    parsed = cast(object, json.loads(body))

    if not isinstance(parsed, dict):
        return None

    data_obj = cast(dict[str, object], parsed)

    text_obj = data_obj.get("response")

    if not isinstance(text_obj, str):
        return None

    text = text_obj.strip()

    if not text:
        return None

    first_line = text.splitlines()[0].strip()
    first_line = first_line.strip("`").strip()

    return first_line


def ask_ollama_pr_title(
    base_ref: str,
    changed_files: str,
    diff_text: str,
    submodule_logs: str,
    pr_commits: str,
) -> str | None:
    """Ask Ollama for a single PR title."""
    trimmed_diff = diff_text[:MAX_DIFF_CHARS]

    prompt = f"""You write excellent GitHub pull request titles.

Task:
Generate exactly one PR title for this diff range {base_ref}...HEAD.

Rules:
- Output only the title
- One line only
- No quotes
- Max 72 characters
- Use conventional-style format:
  - fix(...)
  - feat(...)
  - chore(...)
  - docs(...)
  - refactor(...)
  - test(...)
- Use format: type(scope): summary
  - scope is optional, so type: summary is valid
- Be specific to the actual change

Changed files:
{changed_files or "(none)"}

Commits in range:
{pr_commits or "(none)"}

Submodule changes:
{submodule_logs or "(none)"}

Diff:
{trimmed_diff}
"""

    payload: dict[str, object] = {
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

    with cast(HTTPResponse, urllib.request.urlopen(request, timeout=80)) as response:
        body = response.read().decode("utf-8")

    parsed = cast(object, json.loads(body))

    if not isinstance(parsed, dict):
        return None

    data_obj = cast(dict[str, object], parsed)

    text_obj = data_obj.get("response")

    if not isinstance(text_obj, str):
        return None

    text = text_obj.strip()

    if not text:
        return None

    first_line = text.splitlines()[0].strip()
    first_line = first_line.strip("`").strip().strip('"').strip("'")

    if not first_line:
        return None

    return first_line


def sanitize_pr_body(text: str) -> str | None:
    """Return bullet-only markdown body without fenced code blocks."""
    lines = text.splitlines()
    bullets: list[str] = []
    in_code_fence = False

    for line in lines:
        stripped = line.strip()

        if stripped.startswith("```"):
            in_code_fence = not in_code_fence
            continue

        if in_code_fence or not stripped:
            continue

        if stripped.startswith("- "):
            bullet_text = stripped[2:].strip()

            if bullet_text:
                bullets.append(f"- {bullet_text}")

            continue

        if stripped.startswith("* "):
            bullet_text = stripped[2:].strip()

            if bullet_text:
                bullets.append(f"- {bullet_text}")

    if not bullets:
        return None

    return "\n".join(bullets)


def ask_ollama_pr_body(
    base_ref: str,
    changed_files: str,
    diff_text: str,
    submodule_logs: str,
    pr_commits: str,
) -> str | None:
    """Ask Ollama for a concise bullet-only PR body."""
    trimmed_diff = diff_text[:MAX_DIFF_CHARS]

    prompt = f"""You write concise GitHub pull request descriptions.

Task:
Generate a PR body for this diff range {base_ref}...HEAD.

Rules:
- Output only markdown bullet points
- No heading, no intro sentence, no conclusion
- No code fences
- 3 to 6 bullets
- Each bullet is one line
- Focus on user-visible impact and key implementation details
- Mention tests/validation only if clearly present in diff
- Do not invent changes not shown in diff

Changed files:
{changed_files or "(none)"}

Commits in range:
{pr_commits or "(none)"}

Submodule changes:
{submodule_logs or "(none)"}

Diff:
{trimmed_diff}
"""

    payload: dict[str, object] = {
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

    with cast(HTTPResponse, urllib.request.urlopen(request, timeout=80)) as response:
        body = response.read().decode("utf-8")

    parsed = cast(object, json.loads(body))

    if not isinstance(parsed, dict):
        return None

    data_obj = cast(dict[str, object], parsed)

    text_obj = data_obj.get("response")

    if not isinstance(text_obj, str):
        return None

    text = text_obj.strip()

    if not text:
        return None

    return sanitize_pr_body(text)


def main() -> int:
    """Script entry point."""
    parsed_args = parse_args(sys.argv[1:])

    if parsed_args is None:
        return 0

    mode, cli_base_ref = parsed_args

    inside = run([
        "git",
        "rev-parse",
        "--is-inside-work-tree",
    ])

    if inside != "true":
        # Quiet exit is best when this is triggered from Neovim.
        return 0

    if mode == "commit":
        diff_kind, diff_text = get_diff()

        if not diff_text:
            return 0

        if diff_kind is None:
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

    base_ref = resolve_pr_base(cli_base_ref)
    pr_diff = get_pr_diff(base_ref)

    if not pr_diff:
        return 0

    changed_files = get_pr_changed_files(base_ref)
    submodule_logs = get_submodule_logs()
    pr_commits = get_pr_commits(base_ref)

    ensure_ollama()

    if mode == "pr_title":
        title = ask_ollama_pr_title(
            base_ref,
            changed_files,
            pr_diff,
            submodule_logs,
            pr_commits,
        )

        if not title:
            return 0

        print(title)

        return 0

    body = ask_ollama_pr_body(
        base_ref,
        changed_files,
        pr_diff,
        submodule_logs,
        pr_commits,
    )

    if not body:
        return 0

    print(body)

    return 0


if __name__ == "__main__":
    sys.exit(main())
