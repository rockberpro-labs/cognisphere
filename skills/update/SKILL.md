---
name: update
description: Maintains an existing cognisphere harness - the .agents/ structure, settings and guards, the memory catalog (index, anti-drift rule, stale notes, dead or overlapping globs, domain declarations) and the rules (read rules, dead or too-broad globs, duplicates, new candidates) - and checks, without writing, the vault in ~/Cognisphere/Projects/ named after the project (when this user has one), the local configuration and the user-level settings that would run the guards twice. Use when the user asks to update, upgrade, review, audit, refresh or repair the agent harness, the .agents, the memory, the rules, the hooks/guards or the settings of a project that already has one, typically after upgrading the plugin or a long stretch of commits. Pass a module (a directory such as src/payments, a named module such as billing, or a feature that spans folders such as authentication) to map or deepen just that one, e.g. when a task enters code that has no note - ask before writing. Pass --note <path> (--note .agents/memory/payments.md) to deepen just that one note. Pass --index to repair just the memory index, MEMORY.md (merge-conflict markers, broken links, missing lines), e.g. after a merge. Pass --catalog to review just the memory catalog (index, anti-drift rule, stale notes, dead or overlapping globs, domain declarations) and the read rules its notes owe, without the settings, other rules, vault or configuration. Pass --project <dir> to maintain a sub-project's harness (a monorepo's frontend/ or backend/), optionally followed by a module inside it.
argument-hint: "[--project <dir>] [module | --note <path> | --index | --catalog]"
---

# update

`<plugin>` in the procedures is `${CLAUDE_PLUGIN_ROOT}`. Read each procedure from
`${CLAUDE_PLUGIN_ROOT}/procedures/` when its step starts, not before.

Maintains the versioned harness, minding what is already in place, and **only checks**
the vault and the local configuration: it reports problems there and never writes to
them.

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1   # not a git repo → stop and say so
```

**Repo layer left untouched** — `AGENTS.local.md` has `## Repo layer` (D30, D31) →
passes 1–4 and § Module write what git tracks: skip them, say so in one line, and run
passes 5–7 only. A module argument, `--index` or `--catalog` → stop: mapping writes `.agents/`, which this repo was
set up without; `/cognisphere:harness` adds the repo layer.

**No vault** — `AGENTS.local.md` missing, or without `## Agent workspace` → this user has
no vault, by choice or not yet (D31): not a defect. Pass 5 and the local-configuration
checks of pass 6 are skipped, with one line: "no vault — `/cognisphere:vault` sets one
up". Only the user-level settings check of pass 6 runs. Exception: `$vault` exists, or a
`settings.local.json` names `~/Cognisphere/` → a vault the configuration lost: report it,
and that `/cognisphere:vault` reconnects it without touching its notes.

**Nothing in place** — no `.agents/` and no `AGENTS.md` → this is not an update: say so,
offer `/cognisphere:install` (both halves) or `/cognisphere:harness` (the repo layer
only), run the chosen one (its skill, from step 0) and stop here.

Arguments: `$ARGUMENTS`. A leading `--project <dir>` → § Sub-project, and what follows
it is the module. Then: no module → the full review below; a module or `--note <path>` →
§ Module; `--index` → § Index; `--catalog` → § Catalog. A bare argument is always a module: a file under `.agents/memory/` given
without `--note` → stop and offer `--note <path>`.

## Full review

The repo side first — these steps write — then the checks, which never write. Each pass
keeps its own rule about what needs a yes; do not batch a later pass's questions into an
earlier one: its findings depend on what the earlier pass fixed. A pass with nothing to
do reports "nothing to do" in one line and the next one starts.

1. **Structure — `scaffold.md`.** Idempotent, never overwrites: symlinks, `AGENTS.md`
   sections, the language line, the anti-drift rule, the root `.gitignore` entries.
   Settle the language here — every later pass reads it from `AGENTS.md`.
2. **Settings — `review-settings.md`.** The deny and allow lists against the template,
   `attribution` against `rules/commit.md`, the deprecated `includeCoAuthoredBy`, old
   agent-kit marketplace and `enabledPlugins` entries, and the repo's guard: its copy in
   `.agents/hooks/guard.sh` against the plugin's, its registration, agent-kit's
   one-guard-per-file copies (D37).
3. **Memory — `review-memory.md`.** No `MEMORY.md` → run `memory.md` (bootstrap) instead.
   - **Mandatory, written without asking:** index integrity (merge-conflict markers
     resolved, every link resolves, every note has an index line, every note links back) and the anti-drift rule
     `rules/memory.md` (missing → the template, translated; present → what the template
     gained, and an obsolete `agent-kit:memory` pointer replaced). The report lists them.
   - **Proposed, written on a yes:** stale notes against their diffs, notes with
     merge-conflict markers, dead or overlapping globs, area notes without `paths:`, `kind:` declarations, language,
     gaps.
4. **Rules — `review-rules.md`.** No `rules/commit.md` → run `rules.md` (full pass)
   instead; it asks the commit policy.
   - **Mandatory, written without asking:** a read rule for every note that owns an
     area (`kind: domain` or `paths:`): first line orders reading the note, globs at
     least as wide as the note's.
   - **Proposed, written on a yes:** dead or too-broad globs, duplicates, oversized
     rules, broken pointers, language, new candidates.
5. **Vault, read-only — `vault-check.md`.** A vault from before D32 still straight under
   `~/Cognisphere/` (the move to `Projects/`); the vault folder, `Human/`, `Agent/`'s
   Home, four folders and template notes; leftovers of the v0.1.0 layout that copy the
   repo into the vault; a repo plan the Vault Guide does not name; the open Harness
   threads, listed for the agent to re-check. Missing items → restore from the backup, or
   `/cognisphere:vault` re-seeds missing notes (never touching existing ones).
   Leftovers → what to move out and delete by hand. **Never create, edit, move or
   delete anything under `~/Cognisphere/`.**
6. **Configuration, check-only — `vault-check.md`.** `settings.local.json`
   (`additionalDirectories`, the `Read` and `Edit` allow rules, the `Human/` and
   `Shared/` deny rules, a `Read` grant over the whole root, inert `Write(...)` rules,
   local hooks), `AGENTS.local.md`'s Agent workspace section
   (with its end-of-session and `Shared/` lines), the `CLAUDE.local.md` symlink, and the user-level
   `~/.claude/settings.json` (agent-kit or a second cognisphere enabled, guard hooks
   registered for the user). **Never edit these files:** the report says what to change by hand, or to run `/cognisphere:vault`
   for a missing one.
7. **One consolidated report.** One section per pass: created, updated, written without
   asking (and why it was mandatory), left on purpose, what still needs the user (old
   marketplace entries, linked hooks, rewrites declined, vault and configuration
   findings with their expected values). Then the follow-ups the passes listed —
   `/cognisphere:update <module>` — as one list. Everything changed is staged by name;
   committing follows `rules/commit.md`. No commit unless the user asks.

   **Sub-projects:** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/subprojects.sh"` (writes
   nothing). Each `harness` line → `/cognisphere:update --project <tag>` in the
   follow-ups; each `candidate` (a `CLAUDE.md` or `.claude/` of its own, no `.agents/`)
   → `/cognisphere:harness --project <tag>`; a sub-project missing from the root
   `AGENTS.md` § Sub-projects → add its line (`scaffold.md` § Sub-projects, step 4).
   This review never maintains a sub-project itself (D38).

## Sub-project — `--project <dir>`

Maintains one sub-project's harness (D38). Resolve it after the preflight's `cd`, so
`<dir>` is relative to the git root (`.` from a session started inside an own-repo
sub-project):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/target.sh" <dir>   # a message → stop and say it
```

`cd` to the printed `top`; every script runs from there with `--project <tag>`, and the
procedures' own commands run in `dir`. No `.agents/` in `dir` → nothing to maintain:
offer `/cognisphere:harness --project <tag>` (or `install`), run the chosen one and
stop.

A module after the flag → § Module, `--index` → § Index, `--catalog` → § Catalog, inside the sub-project. Otherwise the full review, with
these changes:

1. **Structure:** `scaffold.md` § Sub-projects; the sub-project's line in the root
   `AGENTS.md`.
2. **Settings:** `review-settings.md` on the sub-project's `settings.json` and guard
   (`scripts/guards.sh --project <tag> --check`).
3. **Memory** and 4. **Rules:** on the sub-project's catalog and rules, globs relative to
   its folder. Same-repo: `rules/commit.md` should be the link to the root's.
5. **Vault:** skipped: the vault is the root's, and `/cognisphere:update` at the root
   checks it.
6. **Configuration, check-only:** `vault-check.md` § Sub-projects.
7. **Report**, as above, naming the sub-project and its layout.

## Module

`/cognisphere:update <module>` — a directory (`src/payments`), a named module (`billing`)
or a feature that spans folders (`authentication`). It maps or deepens only that module,
and nothing else. After
`--project <dir>`, the module is inside that sub-project, and its note and rule go in the
sub-project's `.agents/`, globs relative to its folder:

1. **`memory.md` in module mode.** Read `MEMORY.md` first; a note already covers the module
   → deepen that one instead of creating a sibling. The note declares the module in
   `paths:`. Ask before writing.
2. **`rules.md` in module mode.** The read rule over the note's `paths:`, plus what the
   area must obey without having read the note.
3. **One index line** in `MEMORY.md` for a new note, with its hook.

**`--note <path>`** — a `.md` file under `.agents/memory/` (relative to the repo root,
or to the sub-project's folder after `--project`) → that note is the one to deepen, and its `paths:` are the module; with no `paths:` (a conceptual note), its
subject is, and it owes no read rule. Steps 1–2 work on that note and its read rule,
never a sibling; step 3 does not apply. The file doesn't exist, or isn't under
`.agents/memory/` → stop and say so. `MEMORY.md` → stop: it is the index, not a note; offer `--index`, which repairs it.

The vault and the local configuration are not touched or checked in this mode. Claude
may run this on its own when a task enters a module with no note; it still asks before
writing.

## Index

`/cognisphere:update --index` repairs `.agents/memory/MEMORY.md` and nothing else, e.g.
after a merge left conflict markers in it (D48). After `--project <dir>`, the
sub-project's. No `MEMORY.md` → stop: there is no index to repair; `/cognisphere:update`
with no argument maps the memory.

Run `review-memory.md` check 2 (index integrity) alone, without asking: it is the memory
contract, written without asking in the full review too. The notes themselves are not
edited, save a missing back-to-index line; a note with conflict markers is listed, with
`/cognisphere:update` (check 5) to merge it. Stage `MEMORY.md` and the notes that got a
back link by name, then report what changed. No other pass runs: no settings, rules,
vault or configuration.

## Catalog

`/cognisphere:update --catalog` reviews the memory catalog and nothing else (D49): pass 3
of the full review, plus the read rules the notes owe. After `--project <dir>`, the
sub-project's. No `MEMORY.md` → stop: there is no catalog to review;
`/cognisphere:update` with no argument maps the memory. The language is the one
`AGENTS.md` declares; none declared → stop and offer the full review, whose structure
pass settles it.

1. **`review-memory.md`, whole.** Mandatory checks without asking, proposed ones on a
   yes, as in the full review.
2. **`review-rules.md` check 1 (read rules) alone, without asking.** A fixed glob, a new
   `paths:` or a `kind: domain` declared in step 1 changes the rule a note owes; leaving
   it would put the rules out of step with the catalog. The proposed rule checks
   (2–8) do not run: list `/cognisphere:update` for them when step 1 changed globs.

Stage what changed by name, then one report: the memory section and the read-rule
section of pass 7. No other pass runs: no structure, settings, other rules, vault or
configuration.
