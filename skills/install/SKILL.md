---
name: install
description: Sets up the whole cognisphere harness in a repository at once - the .agents/ structure (memory, rules, settings, .claude symlink), the memory catalog and AGENTS.md, the commit policy and path-scoped rules, the per-project vault at ~/Cognisphere/<project>/ (Agent/ workspace and Human/ notes) and the gitignored local configuration that points the agent at it - or, leaving a repo it should not change untouched, only the vault and the local configuration, ignored through .git/info/exclude. Use when the user asks to install, set up, initialize or configure the agents directory, the memory base, the vault or the .agents of a repository, or to map the project's memory and rules for the first time. Only creates what is missing; never overwrites.
---

# install

`<plugin>` in the procedures is `${CLAUDE_PLUGIN_ROOT}`. Read each procedure from
`${CLAUDE_PLUGIN_ROOT}/procedures/` when its step starts, not before.

Sets up the two layers: the versioned harness in the repo (`.agents/`), and the
unversioned vault outside it (`~/Cognisphere/<project>/`) with the local configuration
that points the agent there. **Every step only creates what is missing**: what already
exists stays exactly as it is, and the report says which was which. When the repo layer
is left untouched (§ 0), only the vault and the local configuration are set up, and git
sees nothing new.

## 0. Preflight

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1   # not a git repo → stop and say so
```

The mechanical steps are scripts in `${CLAUDE_PLUGIN_ROOT}/scripts/`: run them as the
procedures say, never retype their contents into the shell.

Derive `<project>` and the vault path with `scripts/names.sh` (`vault.md` § Names).
Survey without writing: `scaffold.md` step 1 (including its `git grep` for what names
`.claude/` or `CLAUDE.md`), whether `$vault` exists, whether the local settings and
`AGENTS.local.md` already point at it, whether `AGENTS.local.md` has a `## Repo layer`
section, and `git status --porcelain` (kept for § 7).

Then ask **one round of questions, before writing anything**, in the user's language:

- **Repo layer** — set it up, or leave it untouched (only the vault and the local
  configuration; nothing git tracks changes). Asked first: the questions below depend on
  it. Propose **leave untouched** when `AGENTS.local.md` has `## Repo layer`, or when git
  already tracks `.agents/`, `AGENTS.md`, `CLAUDE.md` or `.claude/` and
  `.agents/rules/memory.md` does not name `/cognisphere:update` (another tool's harness,
  someone else's repo). Otherwise propose **set up**. A user who wants to flip a
  previous "untouched" deletes `## Repo layer` from `AGENTS.local.md` by hand first. Git
  tracks `AGENTS.local.md`, `CLAUDE.local.md` or the local settings file → untouched is
  not possible (step 5 would exit 4): say so with the question.
- **Repo language** — the language of `.agents/` and `AGENTS.md`, proposed from the
  evidence (`scaffold.md` § Language). Skip it when `AGENTS.md` already declares one, or
  the repo layer is left untouched.
- **Project name and vault path** — `~/Cognisphere/<project>/`. The folder exists and this
  repo's local configuration does not point at it → another repo may own it: reuse it,
  or pick another name.
- **Working style** — author or tutor (`vault.md` § Working style), quoting both texts.
- **What will be created** — the repo structure, the vault tree and the three local
  files, each marked "create" or "exists, kept". Repo layer untouched → the vault tree,
  the three local files and the `.git/info/exclude` lines; nothing in the repo.
- **What the move breaks** — repo layer set up only: when `.claude/` or `CLAUDE.md` is
  about to move, the survey's `git grep` hits, each with its proposed fix.

Everything already answered in the user's request counts as answered. The procedures
below keep their own asks (the notes to write, the commit policy); do not batch those
into this round — their questions depend on what the earlier steps found.

**Repo layer left untouched** → skip steps 1–3: they write what git tracks. The guards
still run from the plugin, and `memory-drift-guard` covers the repo's own notes, if any
note declares `paths:`.

## 1. Repo structure — `scaffold.md`

`scripts/scaffold.sh`: `.agents/{memory,rules}` and `.agents/.gitignore`,
`.claude -> .agents`, `settings.json` with the deny and read-only git allow lists, `AGENTS.md` and
`CLAUDE.md -> AGENTS.md`, `rules/memory.md`, and the root `.gitignore` entries for the
local files. Then by hand: the Memory Catalog section and the language line in
`AGENTS.md`, and `rules/memory.md` translated.

## 2. Memory — `memory.md`, bootstrap

Phases 0–4 plus the index (phase 6). It asks before writing, and fans out to
`cognisphere:explorer` for phases 3–5 unless the repo is small. Docs that already hold
the knowledge become pointer notes; the phases cover only the gaps. A catalog that
already exists → only the phases whose output is missing.

## 3. Rules — `rules.md`, full pass

Asks the commit policy (skipped if `rules/commit.md` exists), then writes the read rules
— one per note that owns an area — and the path-scoped rules for the candidates step 2
reported.

## 4. Vault — `vault.md` § Seed

`scripts/seed-vault.sh <project>`: `~/Cognisphere/README.md`,
`<project>/Human/README.md`, and `<project>/Agent/` from
`<plugin>/templates/vault/Agent/` with the mechanical placeholders replaced;
`Log/{{date}}.md` becomes today's note. Keep the list of files created in this run.
`Human/` is written only here, before step 5's deny rule exists.

## 5. Local configuration — `vault.md` § Configure

`scripts/configure.sh <project> <style-file>`: merge the entries into
`.agents/settings.local.json` (not valid JSON → stop); create `AGENTS.local.md` with its
Working style and Agent workspace sections, or append the missing sections; create the
`CLAUDE.local.md` symlink. Repo layer untouched → add `--untouched`: the settings go to
`.claude/settings.local.json` (through the link when `.claude` is one),
`AGENTS.local.md` gains `## Repo layer`, and each file git does not ignore yet gets a
`.git/info/exclude` line. Exit 4 → git tracks one of the three files: nothing was
written; report it and stop, since setting it up would change a tracked file.

## 6. Record the run in `Agent/` — `vault.md` § Fill

Only the notes created in step 4. Nothing from the repo is copied in: the vault holds
only what nothing else holds. The open questions, contradicting docs and undone harness
steps of this run become numbered items in `State/Open Threads.md`; the defects and
improvements the passes came across, in `State/Findings.md`; Session 1 of
`Log/<today>.md` records what was found and which vault and local files were created.
Check that every `[[link]]` resolves (`scripts/check-links.pl`).
Repo layer untouched → no pass ran: only Session 1, and Harness threads for any step
that failed.

## 7. Report

- **Repo:** created vs. already existed, per file. Repo layer untouched → compare
  `git status --porcelain` with the survey's: identical → "repo untouched"; any new line
  is a defect of this run, reported as such, never staged.
- **Vault:** the tree, the open threads recorded, the `Human/` notes found (listed, not
  summarised).
- **Configuration:** the three local files, created or extended, and their ignore status.
- **Drift guard coverage** (repo layer set up): the notes that declare `paths:`, with
  their globs. None → say so plainly: `memory-drift-guard` and the read rules cover no
  code until a note declares an area (`/cognisphere:update <area>`).
- **Open questions** the memory pass could not answer, and any code defect found, by
  its number in `State/Findings.md`: it waits there until the maintainer opens an issue.
- **Restart the session** so `CLAUDE.local.md` loads. When `.claude` is a symlink,
  Claude Code treats `settings.local.json` as supplied by the repo: its allow rules and
  `additionalDirectories` wait until the folder is trusted (deny rules always apply).
- **Backups:** nothing under `~/Cognisphere/` is in git and the plugin never backs it up;
  point at `~/Cognisphere/README.md`.
- Repo changes are staged by name (`git add <file>…`, never `-A`); committing follows
  `rules/commit.md`. No commit unless the user asks.
