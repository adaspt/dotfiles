# Git workflow

I stage changes once I've reviewed them, keep working, review again and stage
again, and commit everything only when the whole set is ready. The index is my
record of what I've already reviewed.

- Don't stage, unstage or commit unless I ask. Leave your edits unstaged so
  `git diff` shows exactly what I haven't reviewed yet.
- Editing a file that already has staged changes is fine; just mention it.
- Ask before running anything that changes the index or discards work, such as
  `git stash`, `git reset`, `git restore` or `git checkout -- <file>`.
