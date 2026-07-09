---
name: commit
description: Use when the user asks Codex to commit the current Git changes.
---

# Commit

Prepare git commit(s) according to the user's leading flags (`staged`, `split`, and/or `push`) and treat any remaining input as extra instruction:

- `staged`: commit only staged changes. Inspect only staged changes for commit content; inspect recent commits only to match repository style and scope conventions. Do not include unstaged or untracked changes unless explicitly asked.
- `split`: make multiple focused commits; do NOT mix unrelated changes into a single commit
- `push`: proceed to stage as needed, create the commit(s), then run `git push` separately

Without `staged`, inspect git status, staged changes, unstaged changes, untracked files, and recent commits. Show detected changes, staging/grouping plan, and proposed commit message(s) before committing.

Commit style:

- Use `type(scope/subscope): imperative lowercase subject`
- For large changes, include a concise multiline body with bullets to break down the changes
- Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`
- Use `deps` for dependency updates and `repo` only for repo-wide changes
- Avoid generic scopes unless the repo uses them
- `scope` and `subscope` are optional, use them to add useful context

If `split` is absent, prefer a single focused commit unless the changes clearly require separation.
If `push` is absent, stop and ask for confirmation before running `git add`, creating any commit, or pushing. If `push` is present, proceed to stage as needed, create the commit(s) without re-confirmation, and push.
Always run `git push` separately from other commands; avoid combining it with `git add`, `git commit`, or other commands.
Stop and ask before committing or pushing if conflicts exist, unsafe/sensitive files are involved, the target branch/remote is unclear, any operation would be destructive, or anything is unclear. Never force-push or do risky/destructive actions without explicit confirmation.
