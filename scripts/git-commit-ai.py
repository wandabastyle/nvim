#!/usr/bin/env python3

import subprocess
import sys

def run(cmd):
    """Run a shell command and return the output."""
    result = subprocess.run(
        cmd,
        text=True,
        capture_output=True,
    )

    if result.returncode != 0:
        return None

    return result.stdout.strip()


