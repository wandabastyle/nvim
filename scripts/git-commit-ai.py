#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from collections.abc import Sequence
from dataclasses import dataclass
from http.client import HTTPResponse
from typing import Literal, cast

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
OLLAMA_TAGS_URL = "http://127.0.0.1:11434/api/tags"
MODEL = "qwen2.5-coder:7b"
MAX_DIFF_CHARS = 12000
SUBMODULE_LOG_COUNT = 5
DEFAULT_PR_BASE = "origin/main"
HISTORY_CACHE_VERSION = 2
HISTORY_SAMPLE_SIZE = 200
HISTORY_TOKEN_LIMIT = 40

RAW_DIFF_LINE_RE = re.compile(
    r"^:(\d{6}) (\d{6}) ([0-9a-f]{7,40}) ([0-9a-f]{7,40}) ([A-Z]\d{0,3})\t(.+)$"
)


@dataclass(frozen=True)
class RawDiffEntry:
    old_mode: str
    new_mode: str
    old_sha: str
    new_sha: str
    status: str
    path: str


@dataclass(frozen=True)
class SubmoduleChange:
    path: str
    old_sha: str
    new_sha: str
    status: Literal["updated", "added", "removed"]


_history_cache_loaded = False
_history_cache_data: dict[str, object] = {}


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


def get_history_cache_path() -> str:
    """Return absolute path to the persistent history cache file."""
    xdg_cache_home = os.environ.get("XDG_CACHE_HOME", "").strip()

    if xdg_cache_home:
        base_dir = xdg_cache_home
    else:
        base_dir = os.path.expanduser("~/.cache")

    return os.path.join(
        base_dir,
        "git-commit-ai",
        f"history_profile_v{HISTORY_CACHE_VERSION}.json",
    )


def load_history_cache() -> dict[str, object]:
    """Load cache JSON once per process and return mutable cache data."""
    global _history_cache_loaded
    global _history_cache_data

    if _history_cache_loaded:
        return _history_cache_data

    _history_cache_loaded = True
    path = get_history_cache_path()

    try:
        with open(path, encoding="utf-8") as handle:
            parsed = cast(object, json.load(handle))

        if not isinstance(parsed, dict):
            _history_cache_data = {
                "version": HISTORY_CACHE_VERSION,
                "repos": {},
            }
            return _history_cache_data

        version = parsed.get("version")

        if version != HISTORY_CACHE_VERSION:
            _history_cache_data = {
                "version": HISTORY_CACHE_VERSION,
                "repos": {},
            }
            return _history_cache_data

        repos = parsed.get("repos")

        if not isinstance(repos, dict):
            repos = {}

        _history_cache_data = {
            "version": HISTORY_CACHE_VERSION,
            "repos": repos,
        }

    except Exception:
        _history_cache_data = {
            "version": HISTORY_CACHE_VERSION,
            "repos": {},
        }

    return _history_cache_data


def save_history_cache() -> None:
    """Persist the in-memory history cache JSON."""
    if not _history_cache_loaded:
        return

    path = get_history_cache_path()
    parent_dir = os.path.dirname(path)

    try:
        os.makedirs(parent_dir, exist_ok=True)
        tmp_path = f"{path}.tmp"

        with open(tmp_path, "w", encoding="utf-8") as handle:
            json.dump(
                _history_cache_data,
                handle,
                ensure_ascii=True,
                sort_keys=True,
                indent=2,
            )
            handle.write("\n")

        os.replace(tmp_path, path)

    except Exception:
        return


def get_current_repo_root() -> str | None:
    """Return the current git top-level path, if available."""
    root = run([
        "git",
        "rev-parse",
        "--show-toplevel",
    ])

    if not root:
        return None

    return root


def resolve_history_repo_root() -> str | None:
    """Resolve repo used for persistent history-based scoring."""
    env_repo = os.environ.get("GIT_COMMIT_AI_HISTORY_REPO", "").strip()

    if env_repo:
        resolved = run([
            "git",
            "-C",
            env_repo,
            "rev-parse",
            "--show-toplevel",
        ])

        if resolved:
            return resolved

    return get_current_repo_root()


def get_history_path_head(repo_root: str, submodule_path: str) -> str | None:
    """Return latest commit hash touching the path in the history repo."""
    return run([
        "git",
        "-C",
        repo_root,
        "log",
        "-n",
        "1",
        "--format=%H",
        "--",
        submodule_path,
    ])


def tokenize_history_text(text: str) -> list[str]:
    """Tokenize normalized description text for history profiling."""
    tokens = re.findall(r"[a-z0-9][a-z0-9._-]*", text.lower())
    blocked = {
        "the",
        "and",
        "for",
        "with",
        "from",
        "into",
        "that",
        "this",
        "nvim",
        "config",
    }

    return [token for token in tokens if token not in blocked and len(token) > 2]


def build_history_profile(repo_root: str, submodule_path: str) -> dict[str, object]:
    """Build a per-submodule profile from recent parent repo subjects."""
    subjects = run([
        "git",
        "-C",
        repo_root,
        "log",
        "--pretty=format:%s",
        "-n",
        str(HISTORY_SAMPLE_SIZE),
        "--",
        submodule_path,
    ])

    verb_counts: dict[str, int] = {}
    token_counts: dict[str, int] = {}
    usable = 0

    for raw_subject in (subjects or "").splitlines():
        description = clean_submodule_description(raw_subject)

        if not description:
            continue

        usable += 1
        words = description.lower().split()

        if words:
            first_word = words[0]
            verb_counts[first_word] = verb_counts.get(first_word, 0) + 1

        for token in tokenize_history_text(description):
            token_counts[token] = token_counts.get(token, 0) + 1

    sorted_tokens = sorted(
        token_counts.items(),
        key=lambda item: (-item[1], item[0]),
    )[:HISTORY_TOKEN_LIMIT]

    return {
        "usable_subjects": usable,
        "verb_counts": verb_counts,
        "token_counts": {token: count for token, count in sorted_tokens},
    }


def get_history_profile(submodule_path: str) -> dict[str, object]:
    """Get cached or rebuilt profile for a specific submodule path."""
    repo_root = resolve_history_repo_root()

    if not repo_root:
        return {}

    cache_data = load_history_cache()
    repos_obj = cache_data.get("repos")

    if not isinstance(repos_obj, dict):
        repos_obj = {}
        cache_data["repos"] = repos_obj

    repo_entry_obj = repos_obj.get(repo_root)

    if not isinstance(repo_entry_obj, dict):
        repo_entry_obj = {}
        repos_obj[repo_root] = repo_entry_obj

    current_head = get_history_path_head(repo_root, submodule_path) or ""
    path_entry_obj = repo_entry_obj.get(submodule_path)

    if isinstance(path_entry_obj, dict):
        watermark = path_entry_obj.get("watermark")
        profile_obj = path_entry_obj.get("profile")

        if watermark == current_head and isinstance(profile_obj, dict):
            return profile_obj

    profile = build_history_profile(repo_root, submodule_path)
    repo_entry_obj[submodule_path] = {
        "watermark": current_head,
        "profile": profile,
        "updated_at": int(time.time()),
    }
    save_history_cache()

    return profile


def parse_raw_diff_entries(raw_diff: str) -> list[RawDiffEntry]:
    """Parse `git diff --raw` output into structured entries."""
    entries: list[RawDiffEntry] = []

    for line in raw_diff.splitlines():
        match = RAW_DIFF_LINE_RE.match(line.strip())

        if not match:
            continue

        old_mode, new_mode, old_sha, new_sha, status_token, path_part = match.groups()
        status = status_token[0]

        if status in {"R", "C"} and "\t" in path_part:
            _, new_path = path_part.split("\t", 1)
            path = new_path
        else:
            path = path_part

        entries.append(
            RawDiffEntry(
                old_mode=old_mode,
                new_mode=new_mode,
                old_sha=old_sha,
                new_sha=new_sha,
                status=status,
                path=path,
            )
        )

    return entries


def is_zero_sha(sha: str) -> bool:
    """Return True when SHA is all zeroes."""
    return bool(sha) and set(sha) == {"0"}


def is_submodule_entry(entry: RawDiffEntry) -> bool:
    """Return True if the raw diff entry refers to a submodule."""
    return entry.old_mode == "160000" or entry.new_mode == "160000"


def get_submodule_changes_from_raw(raw_diff: str) -> list[SubmoduleChange]:
    """Extract changed submodule pointers from raw diff output."""
    by_path: dict[str, SubmoduleChange] = {}

    for entry in parse_raw_diff_entries(raw_diff):
        if not is_submodule_entry(entry):
            continue

        if is_zero_sha(entry.old_sha):
            status: Literal["updated", "added", "removed"] = "added"
        elif is_zero_sha(entry.new_sha):
            status = "removed"
        else:
            status = "updated"

        by_path[entry.path] = SubmoduleChange(
            path=entry.path,
            old_sha=entry.old_sha,
            new_sha=entry.new_sha,
            status=status,
        )

    return [by_path[path] for path in sorted(by_path)]


def get_submodule_log_lines(change: SubmoduleChange) -> list[str]:
    """Return up to SUBMODULE_LOG_COUNT commit subjects for a submodule change."""
    if change.status != "updated":
        return []

    forward_log = run([
        "git",
        "-C",
        change.path,
        "log",
        "--oneline",
        "-n",
        str(SUBMODULE_LOG_COUNT),
        f"{change.old_sha}..{change.new_sha}",
    ])

    if forward_log:
        return forward_log.splitlines()

    reverse_log = run([
        "git",
        "-C",
        change.path,
        "log",
        "--oneline",
        "-n",
        str(SUBMODULE_LOG_COUNT),
        f"{change.new_sha}..{change.old_sha}",
    ])

    if reverse_log:
        return reverse_log.splitlines()

    return []


def short_sha(sha: str) -> str:
    """Return a short SHA representation."""
    if is_zero_sha(sha):
        return "0000000"

    return sha[:10]


def build_submodule_context(changes: Sequence[SubmoduleChange]) -> str:
    """Build deterministic submodule context for the model prompt."""
    if not changes:
        return ""

    sections: list[str] = []

    for change in sorted(changes, key=lambda item: item.path):
        header = (
            f"- {change.path} [{change.status}] "
            f"{short_sha(change.old_sha)} -> {short_sha(change.new_sha)}"
        )
        lines = [header]
        commits = get_submodule_log_lines(change)

        if commits:
            for commit in commits:
                lines.append(f"  - {commit}")

        sections.append("\n".join(lines))

    return "\n\n".join(sections)


def clean_submodule_description(subject: str) -> str:
    """Normalize a submodule commit subject into a short description."""
    text = subject.strip()

    if not text:
        return ""

    if " " in text:
        first, rest = text.split(" ", 1)

        if re.fullmatch(r"[0-9a-f]{7,40}", first):
            text = rest.strip()

    text = text.strip("`\"'").strip()
    text = re.sub(r"^[a-z]+(?:\([^\)]*\))?!?:\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"^[a-z0-9._-]+:\s+", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*\([0-9a-f]{7,40}\)\s*$", "", text, flags=re.IGNORECASE)
    text = text.rstrip(".")
    text = re.sub(r"\s+", " ", text).strip()

    if not text:
        return ""

    lowered = text.lower()

    blocked_patterns = [
        r"^merge\b",
        r"^release\b",
        r"^chore\(release\)",
        r"\bbump\s+version\b",
        r"\bmerge\s+pull\s+request\b",
        r"\blatest\s+commits?\b",
    ]

    if any(re.search(pattern, lowered) for pattern in blocked_patterns):
        return ""

    if lowered in {
        "update",
        "updates",
        "updated",
        "bump",
        "bump deps",
        "latest",
        "sync",
        "change",
        "changes",
        "fix",
        "fixes",
    }:
        return ""

    if text[0].isalpha():
        text = text[0].lower() + text[1:]

    return text


def history_affinity_score(text: str, history_profile: dict[str, object]) -> int:
    """Return history-based affinity score for a description."""
    score = 0
    lowered = text.lower()
    words = lowered.split()

    verbs_obj = history_profile.get("verb_counts")

    if isinstance(verbs_obj, dict) and words:
        first_word = words[0]
        first_count = verbs_obj.get(first_word)

        if isinstance(first_count, int):
            score += min(3, first_count)

    tokens_obj = history_profile.get("token_counts")

    if isinstance(tokens_obj, dict):
        tokens = set(tokenize_history_text(text))

        for token in tokens:
            token_count = tokens_obj.get(token)

            if isinstance(token_count, int):
                score += min(2, token_count)

    return score


def score_submodule_description(text: str, history_profile: dict[str, object]) -> int:
    """Return a heuristic score for description quality."""
    score = 0
    words = text.split()
    lowered = text.lower()

    if 4 <= len(words) <= 12:
        score += 2

    if re.match(r"^(add|fix|refactor|improve|clean|optimize|simplify|handle)\b", lowered):
        score += 2

    if any(term in lowered for term in {"nvim", "config", "keymap", "lsp", "plugin"}):
        score += 1

    if any(term in lowered for term in {"update", "changes", "misc", "cleanup", "stuff"}):
        score -= 1

    score += history_affinity_score(text, history_profile)

    return score


def choose_submodule_description(
    commit_lines: Sequence[str],
    history_profile: dict[str, object],
) -> str:
    """Choose the most descriptive normalized subject from commit lines."""
    best_description = ""
    best_score = -10_000

    for commit_line in commit_lines[:SUBMODULE_LOG_COUNT]:
        description = clean_submodule_description(commit_line)

        if not description:
            continue

        score = score_submodule_description(description, history_profile)

        if score > best_score:
            best_score = score
            best_description = description

    return best_description


def is_submodule_only_change(raw_diff: str) -> bool:
    """Return True if raw diff contains only submodule entries."""
    entries = parse_raw_diff_entries(raw_diff)

    if not entries:
        return False

    return all(is_submodule_entry(entry) for entry in entries)


def fallback_submodule_subject(changes: Sequence[SubmoduleChange]) -> str | None:
    """Return a deterministic commit/PR subject for submodule-only changes."""
    sorted_changes = sorted(changes, key=lambda item: item.path)

    if not sorted_changes:
        return None

    if len(sorted_changes) == 1:
        change = sorted_changes[0]
        name = os.path.basename(change.path.rstrip("/")) or change.path
        sha = short_sha(change.new_sha)
        history_profile = get_history_profile(change.path)

        if change.status == "added":
            return f"chore(submodule): add {name} ({sha})"

        if change.status == "removed":
            return f"chore(submodule): remove {name}"

        commit_lines = get_submodule_log_lines(change)

        if commit_lines:
            description = choose_submodule_description(commit_lines, history_profile)

            if description:
                return f"chore(submodule): {name}: {description} ({sha})"

        return f"chore(submodule): sync upstream changes in {name} ({sha})"

    return f"chore(submodules): update {len(sorted_changes)} submodules"


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


def get_commit_raw_diff(diff_kind: Literal["staged", "working"]) -> str:
    """Return raw diff for commit mode."""
    cmd = [
        "git",
        "diff",
        "--raw",
    ]

    if diff_kind == "staged":
        cmd.append("--cached")

    raw_diff = run(cmd)

    if not raw_diff:
        return ""

    return raw_diff


def get_pr_raw_diff(base_ref: str) -> str:
    """Return raw diff for PR mode."""
    raw_diff = run([
        "git",
        "diff",
        "--raw",
        f"{base_ref}...HEAD",
    ])

    if not raw_diff:
        return ""

    return raw_diff


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
    submodule_context: str,
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
- Avoid vague phrases like "latest commit" or "latest commits"

Changed files:
{changed_files or "(none)"}

Submodule changes:
{submodule_context or "(none)"}

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


def normalize_subject(text: str) -> str:
    """Normalize generated subject line formatting."""
    normalized = text.strip().strip("`").strip().strip('"').strip("'")

    normalized = re.sub(r"\s+", " ", normalized)
    normalized = normalized.replace("latest commit(s)", "submodule pointers")
    normalized = normalized.replace("latest commits", "submodule pointers")
    normalized = normalized.replace("latest commit", "submodule pointer")

    return normalized


def ask_ollama_pr_title(
    base_ref: str,
    changed_files: str,
    diff_text: str,
    submodule_context: str,
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
- Avoid vague phrases like "latest commit" or "latest commits"

Changed files:
{changed_files or "(none)"}

Commits in range:
{pr_commits or "(none)"}

Submodule changes:
{submodule_context or "(none)"}

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
    submodule_context: str,
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
- Avoid vague phrases like "latest commit" or "latest commits"

Changed files:
{changed_files or "(none)"}

Commits in range:
{pr_commits or "(none)"}

Submodule changes:
{submodule_context or "(none)"}

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
        raw_diff = get_commit_raw_diff(diff_kind)
        submodule_changes = get_submodule_changes_from_raw(raw_diff)
        submodule_context = build_submodule_context(submodule_changes)

        if is_submodule_only_change(raw_diff):
            fallback_subject = fallback_submodule_subject(submodule_changes)

            if fallback_subject:
                print(fallback_subject)
                return 0

        ensure_ollama()

        message = ask_ollama(
            diff_kind,
            changed_files,
            diff_text,
            submodule_context,
        )

        if not message:
            return 0

        print(normalize_subject(message))

        return 0

    base_ref = resolve_pr_base(cli_base_ref)
    pr_diff = get_pr_diff(base_ref)

    if not pr_diff:
        return 0

    changed_files = get_pr_changed_files(base_ref)
    pr_raw_diff = get_pr_raw_diff(base_ref)
    submodule_changes = get_submodule_changes_from_raw(pr_raw_diff)
    submodule_context = build_submodule_context(submodule_changes)
    pr_commits = get_pr_commits(base_ref)

    if mode == "pr_title" and is_submodule_only_change(pr_raw_diff):
        fallback_title = fallback_submodule_subject(submodule_changes)

        if fallback_title:
            print(fallback_title)
            return 0

    ensure_ollama()

    if mode == "pr_title":
        title = ask_ollama_pr_title(
            base_ref,
            changed_files,
            pr_diff,
            submodule_context,
            pr_commits,
        )

        if not title:
            return 0

        print(normalize_subject(title))

        return 0

    body = ask_ollama_pr_body(
        base_ref,
        changed_files,
        pr_diff,
        submodule_context,
        pr_commits,
    )

    if not body:
        return 0

    print(body)

    return 0


if __name__ == "__main__":
    sys.exit(main())
