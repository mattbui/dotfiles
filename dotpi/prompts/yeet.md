---
description: Stage, commit, and optionally push changes
argument-hint: "[staged] [split] [push]"
---

Help me stage, commit, and optionally push changes.

Arguments: `$ARGUMENTS`

Treat arguments as unordered flags:

- `staged`: inspect only staged changes
- `split`: split changes into sensible commits
- `push`: push after committing
- duplicate flags are okay
- unknown flags: stop and ask

Inspect only git state/diffs, not tests:

- status, staged diff, unstaged diff, untracked files
- recent commits to infer style/scopes
- branch/upstream only if `push` is requested

Commit format:

Small/cohesive changes:

```text
type(scope): slightly more detailed subject
```

Large, mixed, or multi-area changes:

```text
type(scope): tighter subject

- meaningful change
- meaningful change
```

Preferred types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`

Rules:

- infer scope from touched paths and recent commit history
- avoid generic scopes like `src`, `lib`, `test`, or `docs` unless the repo uses them
- use `deps` for dependency/lockfile updates
- use `repo` only for truly repo-wide changes
- subject is imperative, concise, lowercase unless needed, no trailing period

When `split` is used, create multiple focused commits. Each commit gets its own message in the same format and may be one-line or multiline based on that commit's size/scope. Do not mix unrelated changes in one commit.

Before committing or pushing, show:

- parsed flags
- detected changes
- staging/grouping plan
- proposed commit message(s)

Confirmation policy:

- If `push` is present and changes are safe/clear, proceed with staging, committing, and pushing after showing the plan; do not ask for confirmation.
- If `push` is absent, ask for confirmation before committing.
- Never force-push unless explicitly asked, and always ask before any destructive or risky action.

Stop and ask if:

- not in a git repo
- conflicts exist
- no relevant changes exist
- grouping/type/scope is unclear
- untracked files look risky/unrelated
