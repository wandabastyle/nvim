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

    print(f"using {diff_kind} diff")
    print("changed files:")
    print(changed_files or "(none)")
    print()
    print("first diff line:")
    print(diff_text.splitlines()[0])

    return 0

if __name__ == "__main__":
    sys.exit(main())
