---
name: harness
description: Sets up only the versioned harness in the repo - the .agents/ structure (memory, rules, settings, .claude symlink), the memory catalog and AGENTS.md, the commit policy and path-scoped rules - without the vault or any local file. Also adds the harness to a repo where /cognisphere:vault set up only the vault. Use when the user asks to set up the harness, the .agents, the memory base or the rules without a vault, or to add the harness after setting up only the vault. Only creates what is missing; never overwrites.
---

# harness

`<plugin>` in the procedures is `${CLAUDE_PLUGIN_ROOT}`. Read each procedure from
`${CLAUDE_PLUGIN_ROOT}/procedures/` when its step starts, not before.

Sets up the versioned half: what git tracks, shared with everyone who clones. It never
writes under `~/Cognisphere/` and creates no local file. **Every step only creates what
is missing**: what already exists stays exactly as it is, and the report says which was
which. `/cognisphere:install` runs these steps, then `/cognisphere:vault`'s (D31).

## 0. Preflight

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1   # not a git repo → stop and say so
```

The mechanical steps are scripts in `${CLAUDE_PLUGIN_ROOT}/scripts/`: run them as the
procedures say, never retype their contents into the shell.

Survey without writing: `scaffold.md` step 1 (including its `git grep` for what names
`.claude/` or `CLAUDE.md`), and whether `AGENTS.local.md` has `## Repo layer` and
`## Agent workspace`.

**Another tool's harness** — git tracks `.agents/`, `AGENTS.md`, `CLAUDE.md` or `.claude/`
and `.agents/rules/memory.md` does not name `/cognisphere:update` → say what was found:
setting the harness up changes files the whole team shares, and in someone else's repo
that isn't one person's call. Go on only on an explicit yes.

Then ask **one round of questions, before writing anything**, in the user's language:

- **Repo language** — the language of `.agents/` and `AGENTS.md`, proposed from the
  evidence (`scaffold.md` § Language). Skip it when `AGENTS.md` already declares one.
- **What will be created** — the repo structure, each item marked "create" or "exists,
  kept".
- **Guards** — one multiple-choice question, every box checked by default: which
  checks the repo carries, for everyone who works on it with Claude Code, plugin or
  not (D37). `master-guard` blocks commits, merges, `reset --hard` and pushes on
  `main`/`master` (a team that commits straight to `main` unchecks it); `secret-guard`
  blocks a commit that adds a key, a token or a `.env`; `memory-drift-guard` blocks a
  commit that changes code without its memory note (`SKIP_MEMORY_CHECK=1` covers the one
  case where the note still holds). Say they bind the whole team once committed. Skip
  the question when `scripts/guards.sh --check` prints `registered`: the team chose
  already, and step 1 keeps that choice.
- **What the move breaks** — when `.claude/` or `CLAUDE.md` is about to move, the
  survey's `git grep` hits, each with its proposed fix.
- **From vault-only** — `AGENTS.local.md` has `## Repo layer`: the repo was set up
  without the harness. Say what step 4 changes in the local files — `## Repo layer`
  removed, and the `.git/info/exclude` lines `.gitignore` then covers — and that a real
  `.claude/` holding only `settings.local.json` is merged into
  `.agents/settings.local.json` before it becomes the link. The vault itself is not
  touched.

Everything already answered in the user's request counts as answered. The procedures
below keep their own asks (the notes to write, the commit policy); do not batch those
into this round — their questions depend on what the earlier steps found.

## 1. Repo structure — `scaffold.md`

`scripts/scaffold.sh`: `.agents/{memory,rules}` and `.agents/.gitignore`,
`.claude -> .agents`, `settings.json` with the deny and read-only git allow lists, `AGENTS.md` and
`CLAUDE.md -> AGENTS.md`, `rules/memory.md`, and the root `.gitignore` entries for the
local files. Then by hand: the Memory Catalog section and the language line in
`AGENTS.md`, and `rules/memory.md` translated.

Then `scripts/guards.sh`, with a flag for each guard the user unchecked (`--no-master`,
`--no-secret`, `--no-memory-drift`): it copies the plugin's `hooks/guard.sh` to
`.agents/hooks/guard.sh` and registers it in `.agents/settings.json`. The copy is the
plugin's file, the one exception to create-only: an older copy is replaced
(`updated`). A registration already there is never rewritten. All three unchecked →
skip the script, and say the repo then carries no guards: the plugin runs none (D37).

From vault-only, `.claude/` is a real folder → exit 3. Its `settings.local.json` is the
vault's: merge it into `.agents/settings.local.json`
(`perl scripts/merge-json.pl .agents/settings.local.json .claude/settings.local.json`),
then handle what else `.claude/` holds as `scaffold.md` step 1 says, and rerun.

## 2. Memory — `memory.md`, bootstrap

Phases 0–4 plus the index (phase 6). It asks before writing, and fans out to
`cognisphere:explorer` for phases 3–5 unless the repo is small. Docs that already hold
the knowledge become pointer notes; the phases cover only the gaps. A catalog that
already exists → only the phases whose output is missing.

## 3. Rules — `rules.md`, full pass

Asks the commit policy (skipped if `rules/commit.md` exists), then writes the read rules
— one per note that owns an area — and the path-scoped rules for the candidates step 2
reported.

## 4. From vault-only — `scripts/repo-layer.sh`

Only when `AGENTS.local.md` has `## Repo layer`. It removes the section and each
`.git/info/exclude` line the new `.gitignore` entries make redundant, keeping any line
nothing else covers. From then on `/cognisphere:update` reviews the repo layer too.

## 5. Report

- **Repo:** created vs. already existed, per file.
- **Guards:** which checks the registration runs, and that `.agents/hooks/guard.sh`
  and `.agents/settings.json` are versioned: they run for every teammate from the next
  session.
- **Drift guard coverage:** the notes that declare `paths:`, with their globs. None →
  say so plainly: `memory-drift-guard` and the read rules cover no code until a note
  declares an area (`/cognisphere:update <area>`).
- **Open questions** the memory pass could not answer, and any code defect it came
  across. With a vault (`## Agent workspace` in `AGENTS.local.md`) the agent records
  them there, as its Session Protocol says, like in any session. Without one (or when
  install runs this, which hands them to the vault's § Fill), they are listed in full
  here.
- **Local files** (from vault-only): what step 4 removed and what it kept.
- **Restart the session** so the new rules and settings load. When `.claude` is a
  symlink, Claude Code treats its settings as supplied by the repo: its allow rules wait
  until the folder is trusted (deny rules always apply).
- **No vault:** one line — `/cognisphere:vault` sets up your own, any time.
- Repo changes are staged by name (`git add <file>…`, never `-A`); committing follows
  `rules/commit.md`. No commit unless the user asks.
