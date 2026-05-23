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

```text
<type>(<scope>): <subject>
```

Preferred types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`.

Rules:
- infer scope from touched paths and recent commit history
- avoid generic scopes like `src`, `lib`, `test`, or `docs` unless the repo uses them
- use `deps` for dependency/lockfile updates
- use `repo` only for truly repo-wide changes
- subject is imperative, concise, lowercase unless needed, no trailing period

Message style:
- Small/cohesive changes: one line.
- Large, mixed, or multi-area changes: multiline with a blank line after the subject and concise bullets.

One-line:

```text
type(scope): slightly more detailed subject
```

Multiline:

```text
type(scope): tighter subject

- meaningful change
- meaningful change
```

When `split` is used, create multiple focused commits. Each commit gets its own message in the same format and may be one-line or multiline based on that commit's size/scope. Do not mix unrelated changes in one commit.

Before committing or pushing, show:
- parsed flags
- detected changes
- staging/grouping plan
- proposed commit message(s)
- whether push will happen

Ask for confirmation before committing/pushing.

Stop and ask if:
- not in a git repo
- conflicts exist
- no relevant changes exist
- grouping/type/scope is unclear
- untracked files look risky/unrelated
- push is requested but branch/upstream is unclear
