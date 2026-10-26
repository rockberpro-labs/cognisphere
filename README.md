<p align="center">
  <img src="resources/img/Cognisphere.jpeg" alt="Cognisphere logo" width="160">
</p>

# Cognisphere

A Claude Code plugin that gives the agent a memory it can't let rot, guardrails it can't
talk its way past, and a notebook of its own that lives next to yours.

Without it, every session starts cold. What the agent learned about your code last week
is gone, the docs it reads have drifted from the code, the bug it noticed in passing
scrolled away in a reply, and nothing stops it from committing to `main` or committing a
key.

Cognisphere fixes that in two layers:

- **The harness, in the repo** (`.agents/`, versioned): what the agent needs to know
  about the code, the rules for editing each area, and guards that block bad commits.
- **The vault, outside the repo** (`~/Cognisphere/`, not in git): the agent's notebook
  and yours, side by side.

MIT licensed · Claude Code on Linux, macOS and Windows (Git Bash).

## What you get

| | |
|---|---|
| **Guards** | `master-guard`, `secret-guard`, `memory-drift-guard`: one Bash hook the repo carries, so they run for the whole team, plugin or not |
| **Memory catalog** | `AGENTS.md` + `.agents/memory/` notes with the *why*, kept in sync with the code at commit time |
| **Rules** | `.agents/rules/`: short instructions the harness injects when the agent reads a matching file |
| **Vault** | `Agent/` (open threads, findings, log, scratch) and `Human/` (your notes, read-only to the agent); `Shared/` across projects |
| **Commands** | `/cognisphere:install` (= `harness` + `vault`), `/cognisphere:update [area]`, `/cognisphere:read <note>` |
| **Agents** | explorer, planner, implementer, test-runner, reviewer |

## Quick start

Inside Claude Code, once per machine:

```
/plugin marketplace add rockberpro/cognisphere
/plugin install cognisphere@cognisphere
/reload-plugins
```

Then, in each project, run `/cognisphere:install` and restart the session.

- **Needs** `git` and `perl` with `JSON::PP` (it ships with git). The plugin runs only
  the vault's hooks; the guards are copied into each repo the harness sets up.
- **Only one half?** Run `/cognisphere:harness` for the repo layer or
  `/cognisphere:vault` for your vault. A teammate in a repo that already has the harness
  runs `/cognisphere:vault`.
- **Updating:** `/plugin marketplace update cognisphere`, then restart the session.
- **On Windows**, read [GUIDE.md § Windows](GUIDE.md#windows) first.

## How it fits together

```
 repo (git)                         ~/Cognisphere/ (not in git)
 ┌───────────────────────────┐      ┌───────────────────────────────────┐
 │ AGENTS.md ← CLAUDE.md     │      │ Projects/<project>/               │
 │ .agents/ ← .claude        │      │   Agent/   the agent writes       │
 │   memory/  rules/         │      │     00 Home · State/ · Log/ ...   │
 │   settings.json           │points│   Human/   you write, it reads    │
 │ AGENTS.local.md (ignored) │─────▶│ Shared/    you write, every       │
 │                           │      │            project's agent reads  │
 └───────────────────────────┘      └───────────────────────────────────┘
   shared with the team,              personal, changes every session
   reviewed, changes slowly
```

- **Repo**: `AGENTS.md` and the `.agents/` harness, versioned and shared with everyone
  who clones.
- **Vault**: one folder per project, plus `Shared/` for notes that serve every project.
  Each project's agent reads only its own folder and `Shared/`.
- **Local configuration** (gitignored): `AGENTS.local.md` and
  `.agents/settings.local.json` point the agent at the vault.

When they disagree, **code** > `AGENTS.md` > `.agents/memory/` > the vault > `docs/`.

## A session, end to end

1. **Start.** `CLAUDE.local.md` points the agent at the vault. Its Session Protocol has
   it read `00 Home`, the Open Threads and the latest Log, and check `git log` for what
   changed since.
2. **Entering an area.** The first time the agent reads a file under `src/billing/`, the
   billing rule loads by itself: a few imperative lines, ending with "read
   `.agents/memory/module-billing.md`". The note says why renegotiation recalculates
   interest at settlement, which no amount of reading the code would have told it.
3. **Noticing something.** Outside the task, it spots an unchecked `null` in another
   module. It doesn't fix it unasked; it writes it into Findings, now, instead of
   mentioning it once in a reply.
4. **Committing.** It changed billing code but not the note, so the commit is blocked:

   ```
   BLOCKED by memory-drift-guard: this commit changes code covered by memory notes
   that are not part of the commit:

     .agents/memory/module-billing.md  <- src/billing/renegotiation.ts

   Read each note against the diff and fix whatever the change made wrong or
   incomplete, then stage it with the code. If the note is still accurate, re-run
   the same command prefixed with SKIP_MEMORY_CHECK=1.
   ```

   On `main`, `master-guard` would have blocked it anyway; a `.env` in the commit,
   `secret-guard`.
5. **End.** It appends `## Session N` to today's Log (asked, found, did, changed, not
   verified, next) and opens or closes Open Threads. The next session picks up there.

## The memory catalog

Each fact has one place, chosen by when it must be loaded: `AGENTS.md` for the
non-negotiables every session needs, `.agents/rules/` for what to **obey** when editing
an area, `.agents/memory/` for what to **understand** before deciding.

Notes record the why, not the what: what took time to find out or led someone into a
mistake, never a copy of the code. A note says which paths it covers, and
`memory-drift-guard` won't let a commit change those paths without it. The catalog
starts small and grows by use: `/cognisphere:update <area>` maps an area when a real
task enters it. → [GUIDE.md § The memory catalog](GUIDE.md#the-memory-catalog)

## The vault

The **Cognisphere Vault** is a PKM (Personal Knowledge Management) system: a place where
you capture, link and revisit what you learn, so it builds up instead of scattering
across chats and tabs. Here the agent works in it too. Think of it as an Obsidian
AgentOS that doesn't rely on Obsidian: every note is plain Markdown in plain folders, so
Obsidian is one way to browse it, not a requirement. Any editor, `grep` or sync tool
works just as well.

It holds only what nothing else holds. Git has the history and `.agents/` has the
conventions; what's left is the agent's own:

- **Open Threads**: harness work, questions and decisions waiting on you.
- **Findings**: what it notices outside its task (a bug, a risk, a missing test), written
  the moment it notices, never fixed unasked. Ask "known issues?" and it starts here.
- **Log**: one block per session, so the next one picks up where this one stopped.
- **Preferences**: how you want it to work, from your corrections and the approaches you
  confirmed. It replaces Claude Code's auto-memory and loads at every session start.
- **Scratch**: the agent's workbench for what its work produces (plans, scripts, drafts,
  intermediate output), one folder per day, kept as history. It replaces Claude Code's
  own scratchpad and plans, so backing up the vault backs up the work.

Your notes go in `Human/` (this project) or `Shared/` (every project). The agent reads
them and never writes them. Install also asks whether the agent is your **author** (it
writes the code) or your **tutor** (you write it; it explains and reviews).

**Back it up.** The vault isn't in git and cognisphere never syncs it; add
`~/Cognisphere` to a sync client, Obsidian Sync, Syncthing or a scheduled copy.
→ [GUIDE.md § The vault](GUIDE.md#the-vault), [§ Backups](GUIDE.md#backups)

## Commands

```
/cognisphere:install                 # harness + vault, asked in one round
/cognisphere:harness                 # only the versioned repo layer
/cognisphere:vault                   # only your vault and its local configuration
/cognisphere:update [area]           # maintains the harness; with an area, maps just that one
/cognisphere:read <note> [request]   # reads a vault note you copied in Obsidian
```

Every setup command creates only what is missing and never overwrites.
→ [GUIDE.md § Commands](GUIDE.md#commands)

## Guards

One hook, `.agents/hooks/guard.sh`, runs before every Bash call. `/cognisphere:harness`
copies it into the repo and registers it in `.agents/settings.json`, both versioned,
with the checks you pick (all three by default): they run for everyone on the repo,
with or without the plugin, and `/cognisphere:update` keeps the copy current. It fails
open: an internal error never blocks the session.

- **`master-guard`** blocks commits, merges, `reset --hard` and pushes on `main`/`master`.
- **`secret-guard`** blocks a commit that adds a private key, a known token format or a
  `.env`/keystore file.
- **`memory-drift-guard`** blocks a commit that changes code without the memory note
  covering it.

The vault has its own hooks. They come from the plugin, nothing in the repo registers
them, and they act only where your `AGENTS.local.md` names a vault, so a teammate is
never affected. A SessionStart hook, `session-start`, loads the vault's reading order
into context; `scratch-first` reminds the agent, once and without blocking, to write its
plan in `Scratch/` after a repo edit (and again when the note falls behind);
`scratch-redirect` sends writes meant for Claude Code's scratchpad or auto-memory to the
vault; `plan-mirror` copies plan-mode plans into `Scratch/`; and a Stop hook,
`session-log`, asks once for the end-of-session Log entry when the session changed
something and didn't log it, and for the `Scratch/` working notes when it touched 3 or
more files without them.

The protection of `Human/` and `Shared/` covers Claude's tools, not arbitrary scripts;
turn on the sandbox for that. → [GUIDE.md § Guards](GUIDE.md#guards),
[§ Boundaries and their limits](GUIDE.md#boundaries-and-their-limits)

## More

- [GUIDE.md](GUIDE.md): every command step by step, the guards and their limits,
  backups, Windows, uninstall, language, and what's in this repo.
- [docs/decisions.md](docs/decisions.md): why the plugin is the way it is, and what was
  rejected.
- [CHANGELOG.md](CHANGELOG.md): what changed in each release.
- [CONTRIBUTING.md](CONTRIBUTING.md): releasing, and what belongs in the plugin.
