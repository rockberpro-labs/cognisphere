---
name: install
description: Sets up the whole cognisphere harness in a repository at once - the .agents/ structure (memory, rules, settings, .claude symlink), the memory catalog and AGENTS.md, the commit policy and path-scoped rules, the per-project vault at ~/Cognisphere/<project>/ (Agent/ workspace and Human/ notes) and the gitignored local configuration that points the agent at it. Use when the user asks to install, set up, initialize or configure the agents directory, the memory base, the vault or the .agents of a repository, or to map the project's memory and rules for the first time. Only creates what is missing; never overwrites.
---

# install

`<plugin>` in the procedures is `${CLAUDE_PLUGIN_ROOT}`. Read each procedure from
`${CLAUDE_PLUGIN_ROOT}/procedures/` when its step starts, not before.

Sets up the two layers: the versioned harness in the repo (`.agents/`), and the
unversioned vault outside it (`~/Cognisphere/<project>/`) with the local configuration
that points the agent there. **Every step only creates what is missing**: what already
exists stays exactly as it is, and the report says which was which.

## 0. Preflight

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1   # not a git repo → stop and say so
```

Derive `<project>` and the vault path as `vault.md` § Names says. Survey without
writing: `scaffold.md` step 1, whether `$vault` exists, and whether
`.agents/settings.local.json` and `AGENTS.local.md` already point at it.

Then ask **one round of questions, before writing anything**, in the user's language:

- **Repo language** — the language of `.agents/` and `AGENTS.md`, proposed from the
  evidence (`scaffold.md` § Language). Skip it when `AGENTS.md` already declares one.
- **Project name and vault path** — `~/Cognisphere/<project>/`. The folder exists and this
  repo's local configuration does not point at it → another repo may own it: reuse it,
  or pick another name.
- **Working style** — author or tutor (`vault.md` § Working style), quoting both texts.
- **What will be created** — the repo structure, the vault tree and the three local
  files, each marked "create" or "exists, kept".

Everything already answered in the user's request counts as answered. The procedures
below keep their own asks (the notes to write, the commit policy); do not batch those
into this round — their questions depend on what the earlier steps found.

## 1. Repo structure — `scaffold.md`

`.agents/{memory,rules}` and `.agents/.gitignore`, `.claude -> .agents`, `settings.json`
with the deny list, `AGENTS.md` and `CLAUDE.md -> AGENTS.md` with the Memory Catalog
section and the language line, `rules/memory.md` (translated), and the root `.gitignore`
entries for the local files.

## 2. Memory — `memory.md`, bootstrap

Phases 0–4 plus the index (phase 6). It asks before writing, and fans out to
`cognisphere:explorer` for phases 3–5. A catalog that already exists → only the phases
whose output is missing.

## 3. Rules — `rules.md`, full pass

Asks the commit policy (skipped if `rules/commit.md` exists), then writes the read rules
— one per note that owns an area — and the path-scoped rules for the candidates step 2
reported.

## 4. Vault skeleton — `vault.md` § Skeleton

`~/Cognisphere/README.md`, `<project>/Human/README.md`, and `<project>/Agent/` from
`<plugin>/templates/vault/Agent/` with the mechanical placeholders replaced:
`Log/{{date}}.md` becomes today's note, and `Knowledge/{{Area}}.md` one note per domain in
`.agents/memory/domains.md` (single-domain repo: one per major area). Keep the list of
files created in this run. `Human/` is written only here, before step 5's deny rule exists.

## 5. Local configuration — `vault.md` § Configure

Merge the entries into `.agents/settings.local.json` (not valid JSON → stop); create
`AGENTS.local.md` with its Working style and Agent workspace sections, or append the
missing sections; create the `CLAUDE.local.md` symlink.

## 6. Fill `Agent/` — `vault.md` § Fill

Only the notes created in step 4. Fill each section from the sources its hint names;
what no source says stays *unknown* or *not verified*. Keep the hints, remove
`status: skeleton`, check that every `[[link]]` resolves, and complete Session 1 in
`Log/<today>.md`. It runs after the mapping because Knowledge, the Working Agreement and
the Review Checklist condense the memory catalog and the rules.

**Deferrable:** if steps 2–3 used most of the context, stop after step 5 and say so. The
notes stay `status: skeleton`, and the next session fills them: `AGENTS.local.md` tells
it to ask, then fill per the Vault Guide.

## 7. Report

- **Repo:** created vs. already existed, per file.
- **Vault:** the tree, the sources used, what stayed *unknown* or *not verified*, the
  `Human/` notes found (listed, not summarised), and whether the fill was deferred.
- **Configuration:** the three local files, created or extended, and their ignore status.
- **Open questions** the memory pass could not answer.
- **Restart the session** so `CLAUDE.local.md` loads. Because `.claude` is a symlink,
  Claude Code treats `settings.local.json` as supplied by the repo: its allow rules and
  `additionalDirectories` wait until the folder is trusted (deny rules always apply).
- **Backups:** nothing under `~/Cognisphere/` is in git and the plugin never backs it up;
  point at `~/Cognisphere/README.md`.
- Repo changes are staged by name (`git add <file>…`, never `-A`); committing follows
  `rules/commit.md`. No commit unless the user asks.
