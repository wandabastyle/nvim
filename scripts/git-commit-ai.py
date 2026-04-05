#!/usr/bin/env python3

import subprocess
import sys

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
        "unified=0",
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

if __name__ == "__main__":
    sys.exit(main())
