#!/usr/bin/env python3
"""Stop hook: remind the agent to update docs/agent-notes/<scope>.md if it
edited files under a known scope and didn't touch the corresponding note.

Reads scope→paths map from docs/agent-notes/scope-map.json. Fails open: any
error exits 0 so a broken hook never blocks a real session.
"""
import json
import os
import sys
import fnmatch
from pathlib import Path


EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    # Already in a stop-hook block-loop — let it pass to avoid infinite ping-pong.
    if data.get("stop_hook_active"):
        sys.exit(0)

    transcript_path = data.get("transcript_path")
    cwd = data.get("cwd")
    if not transcript_path or not cwd:
        sys.exit(0)

    cwd_path = Path(cwd)
    scope_map_path = cwd_path / "docs" / "agent-notes" / "scope-map.json"
    if not scope_map_path.exists():
        sys.exit(0)

    try:
        raw = json.loads(scope_map_path.read_text())
    except Exception:
        sys.exit(0)

    # Drop comment-style keys (anything starting with "_").
    scope_map = {k: v for k, v in raw.items() if not k.startswith("_") and isinstance(v, list)}
    if not scope_map:
        sys.exit(0)

    # Walk transcript JSONL and collect file_path values from edit-tool calls.
    touched = set()
    try:
        with open(transcript_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except Exception:
                    continue
                msg = entry.get("message") or {}
                content = msg.get("content")
                if not isinstance(content, list):
                    continue
                for item in content:
                    if not isinstance(item, dict):
                        continue
                    if item.get("type") != "tool_use":
                        continue
                    if item.get("name") not in EDIT_TOOLS:
                        continue
                    fp = (item.get("input") or {}).get("file_path")
                    if fp:
                        touched.add(fp)
    except Exception:
        sys.exit(0)

    if not touched:
        sys.exit(0)

    # Convert to repo-relative paths; drop anything outside the repo.
    rel_touched = []
    for fp in touched:
        try:
            rel = os.path.relpath(fp, cwd)
        except Exception:
            continue
        if rel.startswith(".."):
            continue
        rel_touched.append(rel)

    if not rel_touched:
        sys.exit(0)

    # Determine which scopes were touched and whether their notes were updated.
    note_files_touched = {r for r in rel_touched if r.startswith("docs/agent-notes/")}
    touched_scopes = set()
    for rel in rel_touched:
        if rel.startswith("docs/agent-notes/"):
            continue
        for scope, patterns in scope_map.items():
            matched = False
            for pat in patterns:
                if pat.endswith("/"):
                    if rel == pat.rstrip("/") or rel.startswith(pat):
                        matched = True
                        break
                else:
                    if fnmatch.fnmatch(rel, pat):
                        matched = True
                        break
            if matched:
                touched_scopes.add(scope)

    if not touched_scopes:
        sys.exit(0)

    missing = sorted(
        s for s in touched_scopes
        if f"docs/agent-notes/{s}.md" not in note_files_touched
    )
    if not missing:
        sys.exit(0)

    lines = [
        "Scope notes appear out of date. This session edited files under:",
        "",
    ]
    for s in missing:
        lines.append(f"  - {s}  →  update docs/agent-notes/{s}.md")
    lines.extend([
        "",
        "Per docs/agent-notes/README.md, before ending:",
        "  - If the note doesn't exist, create it from the template.",
        "  - If it exists, update Decisions / Open questions / Recent changes log,",
        "    and bump 'Verified as of' to today + current `git rev-parse --short HEAD`.",
        "  - Skip only if the edits were trivial (typo, rename, comment).",
        "",
        "If you genuinely don't need to update, say so out loud and stop again —",
        "this hook is fail-open and won't block twice.",
    ])

    print(json.dumps({"decision": "block", "reason": "\n".join(lines)}))
    sys.exit(0)


if __name__ == "__main__":
    main()
