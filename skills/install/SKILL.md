---
name: install
description: Sets up the whole cognisphere harness in a repository at once - the versioned repo layer (/cognisphere:harness - .agents/ structure, memory catalog and AGENTS.md, commit policy and path-scoped rules) and then the per-project vault in ~/Cognisphere/Projects/, in a folder named after the project, with the gitignored local configuration that points the agent at it (/cognisphere:vault). Use when the user asks to install, set up, initialize or configure cognisphere, the agents directory, the memory base or the .agents of a repository, or to map the project's memory and rules for the first time. For one half only, use /cognisphere:harness or /cognisphere:vault. Only creates what is missing; never overwrites.
---

# install

Both halves at once: `/cognisphere:harness` (the repo layer, versioned and shared), then
`/cognisphere:vault` (the user's own vault and local files). It always does both: for
one half only, the user runs that command (D31). **Every step only creates what is
missing**: what already exists stays exactly as it is, and the report says which was
which.

Read `${CLAUDE_PLUGIN_ROOT}/skills/harness/SKILL.md` and
`${CLAUDE_PLUGIN_ROOT}/skills/vault/SKILL.md` now, and follow them as below. Each reads
its procedures from `${CLAUDE_PLUGIN_ROOT}/procedures/` when its step starts.

## 0. Preflight

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1   # not a git repo → stop and say so
```

Run both § 0 surveys. **Another tool's harness** (harness § 0) → say what was found and
propose `/cognisphere:vault` instead: it sets up only the vault and the local
configuration, and git sees nothing new. On that choice, run it (its skill, from step 0)
and stop here; on an explicit yes to the harness, go on.

Then ask both § 0 rounds as **one round, before writing anything**: the harness's
questions first (repo language, what will be created, what the move breaks, from
vault-only), then the vault's (project name and vault path, working style, what will be
created). Skip what is already answered or already exists.

## 1. Harness — harness steps 1–4

In order: repo structure, memory, rules, and the vault-only step when it applies. Keep
the open questions, contradicting docs, undone harness steps and code defects the passes
report: step 2 records them.

## 2. Vault — vault steps 1–3

Seed and configure as the vault skill says. After step 1, `names.sh` reports
`repo_layer=cognisphere`, so the local files land where the `.gitignore` entries cover
them. Its step 3 runs the full `vault.md` § Fill: the passes' open questions and harness
steps into `State/Open Threads.md`, their defects and improvements into
`State/Findings.md`, the plan rows into the Vault Guide, and Session 1 of the Log.

## 3. Report

One report, in the harness's order then the vault's, without repeating a line. The
vault's "repo untouched" check is skipped: the harness steps changed the repo on purpose.
Open questions and code defects are listed by their number in `State/Open Threads.md`
and `State/Findings.md`: a defect waits there until the maintainer opens an issue.
Restart the session so `CLAUDE.local.md` loads; point at `~/Cognisphere/README.md` for
backups. Repo changes are staged by name (`git add <file>…`, never `-A`); committing
follows `rules/commit.md`. No commit unless the user asks.
