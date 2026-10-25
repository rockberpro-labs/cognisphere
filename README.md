# Cognisphere

Claude Code plugin that gives a project an agent harness in two layers: a versioned one
inside the repo, and an unversioned vault outside it where the agent keeps its open
threads, session log and scratch work next to your notes.

The repository root is the plugin and also a one-entry marketplace, both called
`cognisphere`, so the plugin installs as `cognisphere@cognisphere`.

## The three parts

- **Repo** (versioned, low entropy): the `.agents/` harness — memory catalog, rules,
  settings — plus the guards that run from this plugin. Shared with everyone who clones.
- **Vault** (unversioned, high entropy): `~/Cognisphere/<project>/`, outside the repo.
  `Agent/` is the agent's workspace, and the agent is its only writer. `Human/` holds
  your notes, and the agent only reads it. You can open the folder as an Obsidian vault.
- **Configuration** (local, gitignored): points the agent at the vault —
  `AGENTS.local.md` (with `CLAUDE.local.md` linked to it) and
  `.agents/settings.local.json`.

```
 repo (git)                                ~/Cognisphere/<project>/ (not in git)
 ┌─────────────────────────────┐           ┌──────────────────────────────┐
 │ AGENTS.md ← CLAUDE.md       │           │ Agent/   agent writes        │
 │ .agents/ ← .claude          │  points   │   00 Home.md                 │
 │   memory/  rules/           │ ───────▶  │   State/ Workflow/           │
 │   settings.json             │           │   Log/   Scratch/            │
 │ AGENTS.local.md   (ignored) │           │ Human/   you write, agent    │
 │ .agents/settings.local.json │           │          reads only          │
 └─────────────────────────────┘           └──────────────────────────────┘
   shared, reviewed, lean                    personal, history, scratch
```

When they disagree, **code** > `AGENTS.md` > `.agents/memory/` > the vault > `docs/`.

## Install

One line, once per machine (Linux or macOS):

```bash
curl -fsSL https://raw.githubusercontent.com/rockberpro/cognisphere/main/install.sh | bash
```

It checks for `claude`, `git` and `perl` with `JSON::PP`, adds the marketplace (or
updates it), installs the plugin (or updates it), and warns if agent-kit is installed
too. Run it again any time to update. `COGNISPHERE_REPO=<url-or-path>` points it at a
mirror.

Or by hand:

```bash
claude plugin marketplace add https://github.com/rockberpro/cognisphere.git
claude plugin install cognisphere@cognisphere
```

The default scope is `user`, which is what you want: the guards then apply to every
repository of yours. Inside Claude Code the same commands exist as
`/plugin marketplace add` and `/plugin install`; after installing mid-session, run
`/reload-plugins`.

## Usage

```
/cognisphere:install          # sets everything up at once
/cognisphere:update [area]    # maintains the harness; with an area, maps just that one
```

**`/cognisphere:install`** asks one round of questions first: the repo language, the
project name and vault path, your working style (the agent as **author**, or as
**tutor** while you write the code), and what will be created. Then it runs, each step
creating only what is missing:

1. the `.agents/` structure, `AGENTS.md`, the symlinks and the `.gitignore` entries;
2. the memory catalog (it asks before writing the notes);
3. the rules (it asks the commit policy);
4. the vault under `~/Cognisphere/<project>/`;
5. the local configuration;
6. the run's open questions in `Agent/`'s Open Threads, and Session 1 of its Log;
7. a report.

Restart the session afterwards so `CLAUDE.local.md` loads.

**`/cognisphere:update`** with no argument reviews the versioned harness: structure,
settings, memory, rules. Index integrity and the anti-drift rules are the memory
contract, so it restores them without asking. Everything else is proposed, and written
only on a yes. Then it **checks** the vault and the local configuration and reports what
is missing or points elsewhere. It never writes to them.

**`/cognisphere:update <area>`** — a directory (`src/payments`), a module (`billing`) or
a subject (`authentication`) — maps or deepens only that area: one note with `paths:`,
its read rule, an index line. Claude may run it itself when a task enters an unmapped
area; it still asks before writing. This is how the catalog grows: by the tasks that
touch it.

The vault is **seeded once**. After install it belongs to you and the agent; the plugin
never maintains it. Re-running install re-seeds only notes that are missing, and never
touches existing ones.

## The `Agent/` scaffold

```
Agent/
├── 00 Home.md            entry point: reading order, ground rules, map
├── State/                Open Threads · History
├── Workflow/             Session Protocol · Vault Guide
├── Log/                  YYYY-MM-DD.md, one "## Session N" block per session
└── Scratch/              README.md + throwaway work
```

**The vault holds only what nothing else holds.** The repo's state and history are in
git. The commands, conventions and area knowledge are in `AGENTS.md` and `.agents/`,
which load into every session anyway. A code defect belongs in an issue. A copy of any
of those in the vault is read twice and goes stale the first time the original changes.
What is left is the agent's own: open threads (harness work, questions and decisions
waiting on you), events git doesn't record, the session log and scratch work.

- Every note ships complete: frontmatter, navigation line, sections, and at most a
  one-line hint comment (`<!-- … -->`) saying what belongs there. Hints are invisible in
  Obsidian's reading view.
- Install writes only what its run found: the open questions into Open Threads, and
  Session 1 of today's Log.
- `Workflow/Vault Guide.md` is the vault's rulebook: what it holds, where everything
  else lives instead, how to maintain it, the conventions. From then on the agent
  maintains and may restructure `Agent/` through its Session Protocol.
- `/cognisphere:update` reports the notes of the v0.1.0 layout (Current State, Working
  Agreement, Review Checklist, `Knowledge/`) in an older vault, with what to move out
  before deleting them. It never deletes them itself.

## Backups

**The vault is yours to back up.** Nothing under `~/Cognisphere/` is in git, and
cognisphere never syncs or copies it. Pick one:

- add `~/Cognisphere` to a sync client (Google Drive for desktop, Dropbox, OneDrive,
  iCloud Drive);
- Obsidian Sync or Syncthing;
- a scheduled `rsync` or `restic` copy.

Test a restore once. Sync clients may create conflict copies; merge them by hand. If the
folder goes missing, `/cognisphere:update` reports it and creates nothing. Restore it
from the backup, or run `/cognisphere:install` to re-seed the notes.
`~/Cognisphere/README.md` repeats this.

## Boundaries and their limits

- `Human/` is protected by a deny rule in `settings.local.json`
  (`Edit(~/Cognisphere/<project>/Human/**)`). It covers Claude's file tools, the Bash file
  commands Claude Code recognizes, and redirects. It does **not** cover arbitrary
  scripts (a `python -c` that opens the file); the sandbox covers those, if you turn it
  on.
- Only `Read` and `Edit` rules are used: `Write(...)` rules never match, because `Edit`
  rules cover the Write tool.
- **Folder trust.** `.claude` is a symlink, so Claude Code treats `settings.local.json`
  as supplied by the repo. Its allow rules and `additionalDirectories` apply only once
  you trust the folder; until then, reading the vault prompts. Deny rules always apply.
- The guards fail open: an internal error never blocks the session.

## What is inside

All three guards are checks in one hook, `hooks/guard.sh`, run before every Bash call.

- **guard `master-guard`** — on `master`/`main`, blocks anything that writes a commit
  there (`commit`, `cherry-pick`, `revert`, `am`, `rebase`), plus `git merge`,
  `git reset --hard` and any `push` that targets the protected branch. `--abort` /
  `--continue` on a stuck sequencer still go through. Test:
  `bash hooks/master-guard.test.sh`.
- **guard `secret-guard`** — blocks a `git commit` whose content looks like a secret: a
  private-key header, a well-known token format (AWS/GitHub/Slack/GCP), or a `.env` or
  keystore (`.p12`/`.pfx`/`.jks`) being added. Test: `bash hooks/secret-guard.test.sh`.
- **guard `memory-drift-guard`** — blocks a `git commit` that touches code covered by a
  memory note (its `paths:` frontmatter) when the note is not in the same commit.
  `SKIP_MEMORY_CHECK=1` in front of the command when the note still holds. Test:
  `bash hooks/memory-drift-guard.test.sh`.
- **skills** `/cognisphere:install` and `/cognisphere:update [area]`. Each runs the steps
  in its `SKILL.md` and reads the procedures from `procedures/` on demand:
  `scaffold`, `memory`, `rules`, `review-settings`, `review-memory`, `review-rules`,
  `vault`.
- **agents** `cognisphere:explorer` (read-only investigator; the memory passes fan out
  to it), `cognisphere:planner` (ordered steps from an explorer report),
  `cognisphere:implementer` (one planned step, code plus the stale note),
  `cognisphere:test-runner` (runs the tests, returns only the failures) and
  `cognisphere:reviewer` (a diff against the project's own memory, rules and commit
  policy).
- **templates** — `settings.json` (the deny list), `rules/memory.md` (the anti-drift
  rule), `settings.local.json` and `AGENTS.local.md` (the local configuration), and
  `vault/` (the vault README, `Human/README.md`, one template per `Agent/` note).

## Uninstall

```bash
claude plugin uninstall cognisphere@cognisphere
claude plugin marketplace remove cognisphere
```

What it wrote stays: `.agents/` and `AGENTS.md` in each repo (versioned, the project's
own), the local files, and `~/Cognisphere/`. Delete those by hand if you want them gone.

## Coming from agent-kit

cognisphere is agent-kit v0.12.0 with seven skills collapsed into two and the vault
added. The guards and the five agents are the same, only renamed, so it replaces
agent-kit entirely. Keeping both would run every guard twice.

```bash
claude plugin uninstall agent-kit@agent-kit
claude plugin marketplace remove agent-kit
curl -fsSL https://raw.githubusercontent.com/rockberpro/cognisphere/main/install.sh | bash
```

Then, in each project, run `/cognisphere:update`. It offers to remove old agent-kit
entries from `settings.json`, and it replaces the `agent-kit:memory` pointer in
`rules/memory.md`. Run `/cognisphere:install` to add the vault and the local
configuration; the existing harness stays as it is.

| agent-kit | cognisphere |
|---|---|
| `scaffold`, `memory`, `rules` | `/cognisphere:install` |
| `update-all`, `update-hooks`, `update-memory`, `update-rules` | `/cognisphere:update` |
| `memory <area>`, `rules <area>` | `/cognisphere:update <area>` |

## Versioning and release gate

`version` in `.claude-plugin/plugin.json` decides whether a machine gets an update.
Without bumping it, every commit counts as a new version. Release flow:

```bash
# 1. change the code   2. bump version in plugin.json (semver)
claude plugin validate . --strict && claude plugin validate .claude-plugin/plugin.json --strict
for t in hooks/*.test.sh; do bash "$t" || break; done
# when a skill or procedure changed: the eval fixtures (costs real runs)
claude plugin eval . --scaffold --allow-tools Bash Write Edit --runs 3
git commit -am "feat: <what changed>"
claude plugin tag cognisphere     # creates cognisphere--v<version>, checking plugin.json
                                  # and the marketplace.json entry agree
git push --follow-tags
```

There is no CI in this repository on purpose; the line above is the gate. On each
machine, re-run `install.sh` (or `claude plugin marketplace update cognisphere`) and
restart the session. To pin a machine to a release:
`claude plugin marketplace add https://github.com/rockberpro/cognisphere.git#cognisphere--v0.1.0`.

## Language

Everything in this repository is in English: code, docs, hook output. What the plugin
generates in a project's `.agents/` and `AGENTS.md` follows **that project's** language,
declared once in `AGENTS.md` (proposed at install, confirmed by you) and read from there
on every run. The vault and `AGENTS.local.md` are always English; domain terms stay as
the code names them. Filenames stay English everywhere.

## Not supported

- **Windows.** The settings use `~` paths and the harness relies on symlinks.
- **Other agent CLIs** (Codex, Cursor, …). `.agents/` and `AGENTS.md` are tool-neutral and
  readable by any of them, but this plugin ships no manifests for them and is not tested
  with them.

## What does not belong here

Two things stay in the repository's own `.agents/`:

- **a script that serves only one project** — reading a specific `.ini`, a homegrown
  linter. It becomes a plugin when a second project needs it.
- **a convention** — the commit standard, the target runtime, the encoding, the notes
  and rules the procedures write. That is information about the repo, and it has to be
  readable by whoever clones it without this plugin. The plugin carries the *procedure*;
  the project keeps the *result*. Nothing here ships a pre-filled note or rule. The
  exceptions are `templates/rules/memory.md`, which states how the catalog is kept, and
  the vault templates, which hold only structure and the vault's own rules.

## Design decisions

Why the plugin is the way it is, and what was considered and rejected:
[docs/decisions.md](docs/decisions.md).
