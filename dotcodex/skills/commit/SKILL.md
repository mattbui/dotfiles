---
name: commit
description: >-
  Use when the user asks to commit changes, plan commits, or draft commit
  messages. Guide commit messages, the commit workflow, and which changes to include.
---

# Commit guidance

Follow these conventions for the user's requested commit workflow.

## Commit flow

- If the user requests a plan, message draft, or message review, provide it without changing Git
  state. Otherwise, stage and commit the scoped changes. Push only when the user requests it.
- Check whether any changes are staged to identify the commit scope.
- If staged changes exist, inspect and plan commits only for those changes. Leave unstaged and
  untracked changes outside the commit unless the user requests otherwise.
- If no staged changes exist, inspect unstaged changes and untracked files. Use the user's requested
  scope. If none is specified, limit the commit to changes made in the current chat.
- Inspect recent commits and repository instructions for style, scope, and any required commit flow.
- Prefer a single focused commit. Split when the user asks or the changes clearly require separate
  commits. Keep unrelated changes separate.
- Before committing, show the detected changes, staging and grouping plan, and proposed messages.
- When the user has requested commits, stage as needed and create them without asking again. If the
  user only requested a plan or messages, stop after providing those.
- Push only when the user requests it. Run `git push` separately from other commands.
- Resolve material uncertainty about scope, conflicts, unsafe or sensitive files, or the target
  branch or remote before taking the affected action. Ask the user when inspection cannot resolve it.
- Never force-push or perform destructive actions without explicit authorization.

## Commit messages

- Use `type(scope/subscope): imperative lowercase subject`.
- Types are `feat`, `fix`, `chore`, `docs`, `refactor`, and `test`.
- Scope and subscope are optional. Use them when they add useful context.
- Use `deps` as the scope for dependency updates and `repo` only for repo-wide changes.
- Avoid generic scopes unless the repository uses them.
- Describe the concrete change in the subject.
- For large changes, add a concise multiline body with bullets that explain the changes.
