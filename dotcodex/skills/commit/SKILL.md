---
name: commit
description: Use when the user asks Codex to commit the current Git changes.
---

# Commit

Help me commit the current git changes.

Flag behavior:

- `staged`: use only staged changes
- `split`: make multiple focused commits; do NOT mix unrelated changes into a single commit
- `push`: push after committing; if clear, proceed without asking

Inspect git status/diffs and recent commits. Show detected changes, plan, and proposed message(s) before committing.

Commit style: `type(scope): imperative lowercase subject`. Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`. Use `deps` for dependency updates and `repo` only for repo-wide changes. Avoid generic scopes unless the repo uses them. Use a concise bullet body for larger commits.

If `push` is absent, ask before committing. Never force-push or do risky/destructive actions without explicit confirmation. Stop and ask if conflicts exist or anything is unclear.

Inputs:

- Flags: parse leading words matching `staged`, `split`, or `push`
- Extra instruction: treat the rest of the user's request as extra instruction; use `none` if absent
