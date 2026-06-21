#!/usr/bin/env python3
"""PreToolUse hook: block git commit commands whose subject does not match
the repo's detected commit-message style (see detect-commit-style.sh).

Triggered from pre-bash-dispatch.sh only when the command is `git commit ...`.
Silently skips when it can't reliably extract the message (unknown shell
construct, no -m flag, etc.) so it never false-blocks."""

from __future__ import annotations

import json
import re
import shlex
import subprocess
import sys
from pathlib import Path

HOOK_DIR = Path(__file__).parent
DETECT_SCRIPT = HOOK_DIR / "detect-commit-style.sh"

JA_RE = re.compile(r"[぀-ゟ゠-ヿ一-鿿]")
# Common gitmoji ranges (covers the set our detector recognises plus general emoji).
EMOJI_RE = re.compile(
    r"[\U0001F300-\U0001FAFF⌀-➿]"
)
TYPE_PREFIX_RE = re.compile(r"^([a-z]+)(\(([^)]+)\))?!?:\s")
HEREDOC_RE = re.compile(
    r"\$\(\s*cat\s+<<[-]?\s*[\"']?(\w+)[\"']?\s*\n(.*?)\n\s*\1\s*\)",
    re.DOTALL,
)


def expand_heredocs(command: str) -> str:
    """Replace ``$(cat <<'EOF' ... EOF)`` substitutions with the body text."""
    return HEREDOC_RE.sub(lambda m: m.group(2), command)


def extract_messages(command: str) -> list[str] | None:
    """Return all -m / --message values in the command, or None if we can't parse."""
    expanded = expand_heredocs(command)
    try:
        tokens = shlex.split(expanded)
    except ValueError:
        return None

    msgs: list[str] = []
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in ("-m", "--message") and i + 1 < len(tokens):
            msgs.append(tokens[i + 1])
            i += 2
            continue
        if tok.startswith("-m") and len(tok) > 2:
            msgs.append(tok[2:])
        elif tok.startswith("--message="):
            msgs.append(tok[len("--message="):])
        i += 1
    return msgs or None


def detect_style() -> dict | None:
    """Run detect-commit-style.sh and parse its additionalContext output."""
    if not DETECT_SCRIPT.exists():
        return None
    try:
        result = subprocess.run(
            [str(DETECT_SCRIPT)],
            input='{"tool_input":{"command":"git commit -m x"}}',
            capture_output=True,
            text=True,
            timeout=5,
        )
    except subprocess.SubprocessError:
        return None

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None

    ctx = payload.get("hookSpecificOutput", {}).get("additionalContext", "")
    if not ctx:
        return None

    gitmoji = "gitmoji" in ctx
    uses_scope = "<scope>" in ctx
    if "English subject, Japanese body" in ctx:
        lang_subject = "english"
        lang_body = "japanese"
    elif "(Japanese)" in ctx:
        lang_subject = "japanese"
        lang_body = "japanese"
    else:  # "(English)" — fully English repo
        lang_subject = "english"
        lang_body = "english"

    return {
        "gitmoji": gitmoji,
        "uses_scope": uses_scope,
        "lang_subject": lang_subject,
        "lang_body": lang_body,
        "context": ctx,
    }


def validate(subject: str, body: str, style: dict) -> list[str]:
    errors: list[str] = []

    m = TYPE_PREFIX_RE.match(subject)
    if not m:
        expected = "<type>(<scope>): " if style["uses_scope"] else "<type>: "
        errors.append(f"subject must start with `{expected}` (Conventional Commits)")
        return errors

    has_scope = m.group(2) is not None
    if style["uses_scope"] and not has_scope:
        errors.append("this repo uses scopes; subject must include one, e.g. `feat(ui): ...`")

    rest = subject[m.end():]
    if style["gitmoji"] and not EMOJI_RE.search(rest):
        errors.append("subject must include a gitmoji right after the type (e.g. ✨ / 🐛 / ♻️)")

    has_ja_subject = bool(JA_RE.search(subject))
    if style["lang_subject"] == "english" and has_ja_subject:
        if style["lang_body"] == "japanese":
            hint = "the body can still be Japanese — this repo uses English subject + Japanese body"
        else:
            hint = "this repo uses fully English commit messages"
        errors.append(f"subject must be in English ({hint})")
    elif style["lang_subject"] == "japanese" and not has_ja_subject:
        errors.append("subject must be in Japanese")

    if body and JA_RE.search(body) and style["lang_body"] == "english":
        errors.append(
            "body must be in English (this repo uses fully English commit messages; "
            "the subject says so too)"
        )

    return errors


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return

    command = data.get("tool_input", {}).get("command", "")
    if not re.search(r"\bgit\s+commit\b", command):
        return

    msgs = extract_messages(command)
    if not msgs:
        # No -m / --message we can read (file message, interactive editor, etc.) — skip.
        return

    style = detect_style()
    if style is None:
        return

    full = "\n\n".join(msgs)
    parts = full.split("\n", 1)
    subject = parts[0].strip()
    body = parts[1].strip() if len(parts) > 1 else ""
    if not subject:
        return

    errors = validate(subject, body, style)
    if not errors:
        return

    reason_lines = [
        "Commit message subject doesn't match this repo's style.",
        "",
        style["context"],
        "",
        "Problems:",
        *(f"- {e}" for e in errors),
        "",
        f"Your subject: {subject!r}",
    ]
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": "\n".join(reason_lines),
                }
            }
        )
    )


if __name__ == "__main__":
    main()
