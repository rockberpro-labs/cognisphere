---
name: update
description: Maintains an existing cognisphere harness - the .agents/ structure, settings and guards, the memory catalog (index, anti-drift rule, stale notes, dead or overlapping globs, domain declarations) and the rules (read rules, dead or too-broad globs, duplicates, new candidates) - and checks, without writing, the vault at ~/Cognisphere/<project>/, the local configuration and the user-level settings that would run the guards twice. Use when the user asks to update, upgrade, review, audit, refresh or repair the agent harness, the .agents, the memory, the rules, the hooks/guards or the settings of a project that already has one, typically after upgrading the plugin or a long stretch of commits. Pass an area (a directory, module or subject) to map or deepen just that one, e.g. when a task enters an area that has no note - ask before writing.
argument-hint: "[area]"
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

**Nothing in place** — no `.agents/` and no `AGENTS.md` → this is not an update: run
`/cognisphere:install` instead (its skill, from step 0) and stop here.

Area argument: `$ARGUMENTS`. Empty → the full review below; otherwise → § Area.

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
   agent-kit marketplace and `enabledPlugins` entries, stale guard copies in
   `.agents/hooks/`.
3. **Memory — `review-memory.md`.** No `MEMORY.md` → run `memory.md` (bootstrap) instead.
   - **Mandatory, written without asking:** index integrity (every link resolves, every
     note has an index line, every note links back) and the anti-drift rule
     `rules/memory.md` (missing → the template, translated; present → what the template
     gained, and an obsolete `agent-kit:memory` pointer replaced). The report lists them.
   - **Proposed, written on a yes:** stale notes against their diffs, dead or
     overlapping globs, area notes without `paths:`, `kind:` declarations, language,
     gaps.
4. **Rules — `review-rules.md`.** No `rules/commit.md` → run `rules.md` (full pass)
   instead; it asks the commit policy.
   - **Mandatory, written without asking:** a read rule for every note that owns an
     area (`kind: domain` or `paths:`): first line orders reading the note, globs at
     least as wide as the note's.
   - **Proposed, written on a yes:** dead or too-broad globs, duplicates, oversized
     rules, broken pointers, language, new candidates.
5. **Vault, read-only — `vault-check.md`.** The vault folder, `Human/`, `Agent/`'s
   Home, four folders and template notes; leftovers of the v0.1.0 layout that copy the
   repo into the vault; a repo plan the Vault Guide does not name; the open Harness
   threads, listed for the agent to re-check. Missing items → restore from the backup, or
   `/cognisphere:install` re-seeds missing notes (never touching existing ones).
   Leftovers → what to move out and delete by hand. **Never create, edit, move or
   delete anything under `~/Cognisphere/`.**
6. **Configuration, check-only — `vault-check.md`.** `settings.local.json`
   (`additionalDirectories`, the `Read` and `Edit` allow rules, the `Human/` deny rule,
   inert `Write(...)` rules, local hooks), `AGENTS.local.md`'s Agent workspace section
   (with its end-of-session line), the `CLAUDE.local.md` symlink, and the user-level
   `~/.claude/settings.json` (agent-kit or a second cognisphere enabled, guard hooks
   registered for the user). **Never edit these files:** the report says what to change by hand, or to run `/cognisphere:install`
   for a missing one.
7. **One consolidated report.** One section per pass: created, updated, written without
   asking (and why it was mandatory), left on purpose, what still needs the user (old
   marketplace entries, linked hooks, rewrites declined, vault and configuration
   findings with their expected values). Then the follow-ups the passes listed —
   `/cognisphere:update <area>` — as one list. Everything changed is staged by name;
   committing follows `rules/commit.md`. No commit unless the user asks.

## Area

`/cognisphere:update <area>` — a directory (`src/payments`), a module (`billing`) or a
subject (`authentication`). It maps or deepens only that area, and nothing else:

1. **`memory.md` in area mode.** Read `MEMORY.md` first; a note already covers the area
   → deepen that one instead of creating a sibling. The note declares the area in
   `paths:`. Ask before writing.
2. **`rules.md` in area mode.** The read rule over the note's `paths:`, plus what the
   area must obey without having read the note.
3. **One index line** in `MEMORY.md` for a new note, with its hook.

The vault and the local configuration are not touched or checked in this mode. Claude
may run this on its own when a task enters an area with no note; it still asks before
writing.
