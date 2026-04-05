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

def run(cmd):
    """
    Run a command and return sripped stdout.

    Return None if the command fails
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
    Return the best availabe git diff.

    We prefer ste staged diff because that is usually closer to what will
    become the next commit.

    Return a tuple:
        (diff_kind, diff_text)

    where diff_kind is:
        "staged"    -> git diff --cached
        "working"   -> git diff

    Return (None, None) if there is no diff
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

    This is a useful context for the LLM because filenames often make the
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

def start_ollama_serve():
    """
    Start 'ollama serve' in the background.

    Return the subprocess handle so we can stop it later.
    """
    try:
        process = subprocess.Popen(
            ["ollama", "serve"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return process

    except FileNotFoundError as exc:
        raise RuntimeError(
            "ollama CLI not found in PATH"
        ) from exc
    
def stop_process(process):
    """
    Stop a process we started ourselves.
    """
    if process.poll() is not None:
        return

    try:
        process.terminate()

        try:
            process.wait(timeout=2.5)

        except subprocess.TimeoutExpired:
            process.kill()
    except Exception:
        pass

def ensure_ollama():
    """
    Ensure Ollama is running.

    Return:
        None    -> Ollama was already running
        process -> this script started it
    """
    if ollama_ping():
        return None

    process = start_ollama_serve()

    for _ in range(25):
        if ollama_ping():
            return process

        time.sleep(0.2)

    stop_process(process)

    raise RuntimeError(
        "Ollama server did not come up"
    )

def ask_ollama(diff_kind, changed_files, diff_text):
    """
    Ask Ollama for a single commit message suggestion.

    We keep the prompt strict so the model returns one short subject line,
    not an explanation or a full commit body.
    """
    trimmed_diff = diff_text[:MAX_DIFF_CHARS]

    prompt = f"""
    You write excelent git commit messages.

    Task:
    Generate exactly one git commit message for thos {diff_kind} diff.

    Rules:
    - Qutput only the commit message
    - No quotes
    - One line only
    - Use conventional commits
    - Keep it under 72 characters if possible
    - Be specific, not generic

    Changed files:
    {changed_files}

    Diff:
    {trimmed_diff}
    """

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "stream": False,
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
    started_process = None

    try:
        started_process = ensure_ollama()

        message = ask_ollama(
            diff_kind,
            changed_files,
            diff_text,
        )

        if not message:
            return 0

        print(message)

        return 0

    finally:
        if started_process is not None:
            stop_process(started_process)

if __name__ == "__main__":
    sys.exit(main())
