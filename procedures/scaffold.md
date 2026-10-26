# scaffold

Sets up a project's `.agents/` skeleton. **Idempotent**: run again on an already
initialized project and it only creates what is missing, touching nothing that exists.
`/cognisphere:harness` (and so `/cognisphere:install`) runs it first; `/cognisphere:update`
runs it as its structure pass.

## Language

These procedures are written in English; what they *generate* in `.agents/` and
`AGENTS.md` is written in the project's language — notes, index, rules, headings, the
"back to the index" line. Every other procedure settles the language here.

That language is a project fact, so it is **declared, not re-guessed** on every run:

1. `AGENTS.md` already declares it (the line under *Memory Catalog*, see step 4) → use it.
2. Otherwise, propose one from the evidence — README, code comments, `git log` subjects —
   and **confirm with the user** before writing anything. Code identifiers in English do
   not make the project English: the team's prose (docs, comments, commit messages)
   decides. Evidence split or absent → ask, do not default.
3. Record the answer in step 4. Any later session — with or without this plugin — then
   writes notes and rules in it, because `AGENTS.md` loads every time.

Filenames, keys and paths stay as specified here regardless (English kebab-case): the
procedures find `rules/memory.md`, `rules/commit.md` and `memory/MEMORY.md` by name.

The vault (`~/Cognisphere/<project>/`) and `AGENTS.local.md` are the exception: they are
always English (`vault.md`), with domain terms kept as the code names them.

## Convention

Everything lives in `.agents/` (tool-neutral) and `.claude` is a symlink to it so
Claude Code sees it. Same idea at the root: the instructions file is `AGENTS.md` and
`CLAUDE.md` is a symlink to it; the personal `AGENTS.local.md` gets `CLAUDE.local.md`
the same way (`vault.md` § Configure).

```
.agents/
  memory/            → note graph, one note per domain, MEMORY.md index (memory.md)
  rules/             → path-scoped instructions the harness injects (rules.md)
  settings.json      → permissions (+ attribution, from rules.md)
  settings.local.json→ personal, gitignored: the vault permissions (vault.md)
  agents/            → project subagents (optional)
  skills/            → project skills (optional)
  hooks/             → this repository's own hooks (optional)
  .gitignore
.claude -> .agents
AGENTS.md
CLAUDE.md -> AGENTS.md
AGENTS.local.md          (gitignored, vault.md)
CLAUDE.local.md -> AGENTS.local.md   (gitignored)
```

## Steps

1. **Survey what already exists** before writing anything. Every step below is
   conditional: what is already there stays as it is (do not overwrite, do not "fix"
   content), what is missing you create. At the end, report created vs. already
   existed.

   ```bash
   cd "$(git rev-parse --show-toplevel)"
   ls -ld .agents .claude AGENTS.md CLAUDE.md .agents/settings.json .agents/rules \
          .agents/rules/memory.md .agents/memory/MEMORY.md .gitignore 2>&1
   git grep -nIF -e .claude/ -e CLAUDE.md -- . ':!.agents' ':!.claude' 2>/dev/null
   ```

   **List the `git grep` hits before moving anything.** Moving `.claude/` into `.agents/`
   or renaming `CLAUDE.md` breaks what names them, silently: a hook that treats
   `.claude/` as a docs prefix now counts `.agents/` edits as code; a `.gitignore` line
   such as `.claude/worktrees/` stops matching, because git sees `.claude` as a symlink
   file; an instruction ("don't move `.claude/`") contradicts the move. For each hit, say
   what the move does to it and propose the fix (usually `.claude/` → `.agents/`), and
   ask with the merge question below. No hits → say so in one line.

   The exceptions where you *do* adjust what exists, because it is structure and not
   content:

   - `CLAUDE.md` is a regular file and `AGENTS.md` does not exist → the script renames
     it (`git mv CLAUDE.md AGENTS.md`) and creates the symlink. Content is preserved.
   - `.agents/settings.json` exists but is missing a `deny` or `allow` entry of the
     template → the script adds what is missing, preserving the rest and its key order.
   - `.claude` or `CLAUDE.md` exists but is **not a symlink** (`[ ! -L .claude ]`): a
     real `.claude/` directory, or a `CLAUDE.md` with its own content next to an
     `AGENTS.md` → a copy made by hand, or a harness from before this plugin. Diff it
     against `.agents/` / `AGENTS.md`, show what only the copy has, and **ask** before
     merging it in and replacing the copy with the link (the script exits 3 until then).

2. **Create whatever structure is missing** — steps 2 to 5 are one script, create-only,
   one line per item:

   ```bash
   bash "<plugin>/scripts/scaffold.sh"
   ```

   It makes `.agents/{memory,rules}`, `.agents/.gitignore` (with `settings.local.json`),
   the `.claude -> .agents` link, `rules/memory.md` from the template, `settings.json`
   (or the `deny` and `allow` entries it lacks), `AGENTS.md` with `CLAUDE.md -> AGENTS.md`, and the
   root `.gitignore` lines. Exit 0 → done; 3 → a real `.claude/` or `CLAUDE.md` is in the
   way (step 1); 2 → `settings.json` is not valid JSON: report it and stop, do not
   hand-edit around it; 1 → no symlink could be made: on Windows, point at README
   § Windows and stop.

   A link line saying `native link via MSYS=winsymlinks:nativestrict` worked, but this
   machine lacks the permanent setup: report README § Windows (`core.symlinks`, the
   `~/.bashrc` line) as a follow-up, not a blocker.

   `rules/memory.md` is the anti-drift rule — the always-on instruction to fix a note in
   the same task that made it wrong, which `memory-drift-guard` then enforces at commit.
   Freshly created, translate it into the project's language (keep the filename).

3. **`.agents/settings.json`** denies blind `git add` and allows the read-only git
   commands (`git status`, `git diff`, `git log`, `git show`) that every pass and agent
   runs, so they don't prompt. Agent co-author attribution is
   the user's choice: `rules.md` asks it with the commit policy and writes `attribution`
   then; do not set it here. Never write `extraKnownMarketplaces` or `enabledPlugins`
   entries for this plugin: the project's config carries the project's policy, not the
   tool that set it up.

   The guards (`master-guard`, `secret-guard`, `memory-drift-guard`) run from the plugin,
   so they act for whoever has it installed. The `deny` list stops a stray `.env` or real
   config from being staged at all; `secret-guard` is the net behind it.

4. **`AGENTS.md` at the root, with `CLAUDE.md` as a symlink to it.** The real file is
   `AGENTS.md` (a convention other CLIs also read); Claude Code sees it through the
   symlink.

   If `AGENTS.md` does not mention the memory yet, append this (leaving the rest
   alone), in the project's language:

   ```markdown
   ## Memory Catalog

   Persistent instructions live in `./.agents/memory/`. Index:
   [.agents/memory/MEMORY.md](.agents/memory/MEMORY.md). Before any action in a
   domain, read the matching file — the rules live there, not here.

   Notes and rules under `.agents/` are written in <language> (`<tag>`).
   ```

   If the section exists but has no language line, add just that line to it. Example
   for a Portuguese project: `Notas e regras em .agents/ são escritas em português
   (pt-BR).`

5. **Root `.gitignore`** — `AGENTS.local.md` and `CLAUDE.local.md` stay out of git (the
   script appends the missing lines; `.agents/settings.local.json` is covered by
   `.agents/.gitignore`).

6. Report what you created (created vs. already existed), the step 1 hits and what was
   done about each, and confirm both links are real (`[ -L .claude ] && [ -L CLAUDE.md ]`).

## What this procedure does NOT do

Anything specific to a single project (a homegrown database client, a homegrown
linter) stays in that repository's own `.agents/hooks/` and `.agents/skills/`. Only
what has already served more than one project becomes a marketplace plugin.

It never touches the vault or the local configuration: that is `vault.md`.
