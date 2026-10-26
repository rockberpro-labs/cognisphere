---
name: vault
description: Sets up only your own per-project vault in ~/Cognisphere/, in a folder named after the project (Agent/ workspace and Human/ notes), and the gitignored local configuration that points the agent at it, without touching the repo's harness. Use when the user asks to set up, add, create or restore their vault, when a teammate joins a repo that already has the cognisphere harness, when the repo's harness belongs to someone else, after /cognisphere:harness, or when /cognisphere:update or /cognisphere:read reports that no vault is set up. Only creates what is missing; never overwrites.
---

# vault

`<plugin>` in the procedures is `${CLAUDE_PLUGIN_ROOT}`. Read
`${CLAUDE_PLUGIN_ROOT}/procedures/vault.md` when step 1 starts, not before.

Sets up the unversioned half for the person running it: the vault outside the repo and
the three local files that point the agent at it. The vault is personal: each person on
a repo runs this, or doesn't. It never writes what git tracks. **Every step only creates
what is missing**: what already exists stays exactly as it is, and the report says which
was which. `/cognisphere:install` runs these steps after `/cognisphere:harness`'s (D31).

## 0. Preflight

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1   # not a git repo → stop and say so
```

The mechanical steps are scripts in `${CLAUDE_PLUGIN_ROOT}/scripts/`: run them as the
procedure says, never retype their contents into the shell.

Survey without writing: `scripts/names.sh` (`vault.md` § Names), whether `$vault`
exists, whether the local settings and `AGENTS.local.md` already point at it, and
`git status --porcelain` (kept for § 4). `repo_layer` says where the local files go:

- **`cognisphere`** — the repo has cognisphere's harness: `.agents/settings.local.json`,
  ignored by the `.gitignore` lines install committed.
- **`untouched`** — another tool's harness, or none: `.claude/settings.local.json`
  (through the link when `.claude` is one), each file ignored through
  `.git/info/exclude`, and `AGENTS.local.md` gains `## Repo layer`. Git tracks
  `AGENTS.local.md`, `CLAUDE.local.md` or that settings file → nothing can be set up
  without changing a tracked file: say so and stop.

Then ask **one round of questions, before writing anything**, in the user's language:

- **Project name and vault path** — `~/Cognisphere/<project>/`. The folder exists and this
  repo's local configuration does not point at it → another repo may own it: reuse it,
  or pick another name.
- **Working style** — author or tutor (`vault.md` § Working style), quoting both texts.
  Skip it when `AGENTS.local.md` already has `## Working style`.
- **What will be created** — the vault tree and the three local files, each marked
  "create" or "exists, kept", plus the `.git/info/exclude` lines when untouched. Nothing
  in the repo.

Everything already answered in the user's request counts as answered.

## 1. Vault — `vault.md` § Seed

`scripts/seed-vault.sh <project>`. Keep the list of files created in this run. `Human/`
is written only here, before step 2's deny rule exists.

## 2. Local configuration — `vault.md` § Configure

`scripts/configure.sh <project> <style-file>`. Exit 4 → git tracks one of the three
files: nothing was written; report it and stop.

## 3. Record the run in `Agent/` — `vault.md` § Fill

Only the notes created in step 1. Run alone, no mapping pass ran: only Session 1 of
`Log/<today>.md`, and a Harness thread in `State/Open Threads.md` for any step that
failed. Run by `/cognisphere:install`, the full § Fill, with what the harness passes
found. Check that every `[[link]]` resolves (`scripts/check-links.pl`).

## 4. Report

- **Repo:** compare `git status --porcelain` with the survey's: identical → "repo
  untouched"; any new line is a defect of this run, reported as such, never staged.
- **Vault:** the tree, created vs. already existed; the `Human/` notes found (listed,
  not summarised).
- **Configuration:** the three local files, created or extended, and their ignore status.
- **Restart the session** so `CLAUDE.local.md` loads. When `.claude` is a symlink,
  Claude Code treats `settings.local.json` as supplied by the repo: its allow rules and
  `additionalDirectories` wait until the folder is trusted (deny rules always apply).
- **Backups:** nothing under `~/Cognisphere/` is in git and the plugin never backs it up;
  point at `~/Cognisphere/README.md`.
