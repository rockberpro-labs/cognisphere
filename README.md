<p align="center">
  <img src="resources/img/Cognisphere.jpeg" alt="Cognisphere logo" width="160">
</p>

# Cognisphere

A Claude Code plugin that gives the agent a memory it can't let rot, guardrails it can't
talk its way past, and a notebook of its own that lives next to yours.

Without it, every session starts cold. What the agent learned about your code last week
is gone, the docs it reads have drifted from the code, the bug it noticed in passing
scrolled away in a reply, and nothing stops it from committing to `main` or committing a
key. Cognisphere fixes that in two layers:

- **in the repo**, a versioned harness (`.agents/`): a memory catalog of what the code
  doesn't say by itself, path-scoped rules that load before the first wrong edit, and
  guards that block a commit to `main`, a commit that leaks a secret, and a commit that
  changes code without its memory note;
- **outside the repo**, a per-project vault (`~/Cognisphere/<project>/`, Obsidian-ready)
  where the agent keeps its open threads, findings, session log and scratch work, and
  where you keep notes it reads but never writes.

## What you get

| | |
|---|---|
| **Guards** | `master-guard`, `secret-guard`, `memory-drift-guard`: one Bash hook, every repo of yours |
| **Memory catalog** | `AGENTS.md` + `.agents/memory/` notes with the *why*, kept in sync with the code at commit time |
| **Rules** | `.agents/rules/`: short instructions the harness injects when the agent reads a matching file |
| **Vault** | `Agent/` (open threads, findings, log, scratch) and `Human/` (your notes, read-only to the agent) |
| **Commands** | `/cognisphere:install` (= `harness` + `vault`), `/cognisphere:update [area]`, `/cognisphere:read <note>` |
| **Agents** | explorer, planner, implementer, test-runner, reviewer |

## Quick start

Inside Claude Code, once per machine:

```
/plugin marketplace add rockberpro/cognisphere
/plugin install cognisphere@cognisphere
/reload-plugins
```

Then, in each project, run `/cognisphere:install` and restart the session. It runs
`/cognisphere:harness` (the repo layer) and `/cognisphere:vault` (your vault); for only
one of them, run that one. A teammate in a repo that already has the harness runs
`/cognisphere:vault`, if they want a vault of their own.

Needs `git` and `perl` with `JSON::PP` (it ships with git). Keep the default `user`
scope, so the guards apply to every repository of yours. If agent-kit is installed,
remove it first ([Coming from agent-kit](#coming-from-agent-kit)). On Windows, see
[Windows](#windows).

To update later: `/plugin marketplace update cognisphere`, then restart the session.

## How it fits together

The repository root is the plugin and also a one-entry marketplace, both called
`cognisphere`, so the plugin installs as `cognisphere@cognisphere`. What it sets up in a
project has three parts:

- **Repo** (versioned, low entropy): `AGENTS.md` and the `.agents/` harness — memory
  catalog, rules, settings. Shared with everyone who clones.
- **Vault** (unversioned, high entropy): `~/Cognisphere/<project>/`. `Agent/` is the
  agent's workspace, and the agent is its only writer. `Human/` holds your notes, and
  the agent only reads it. You can open the folder as an Obsidian vault.
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
4. **Committing.** It changed billing code but not the note. `memory-drift-guard` blocks
   the commit until the note is updated and staged with it. On `main`, `master-guard`
   would have blocked it anyway; a `.env` in the commit, `secret-guard`.
5. **End.** It appends `## Session N` to today's Log (asked, found, did, changed, not
   verified, next) and opens or closes Open Threads. The next session picks up there.

## The memory catalog

Each fact has one place, chosen by when it must be loaded:

| Destination | Loaded | What goes there |
|---|---|---|
| `AGENTS.md` | every session | the project's non-negotiables, in few lines: runtime, encoding, commands, what CI really runs |
| `.agents/rules/` | when a file matching the rule's `paths:` is read | what to **obey** when editing that area — short, imperative |
| `.agents/memory/` | when the agent opens the note | what to **understand** to decide — the why, the measurements, the traps already paid for |

- **Notes record the why, not the what.** Class names and layouts are read from the code
  in seconds; a note earns its place with what took time to find out or led someone into
  a mistake. No code copies, no line numbers, no speculation.
- **A note that owns an area says so** in a `paths:` frontmatter, and gets a **read
  rule** over the same globs, so the agent reads it at its first look into the area, not
  only at commit.
- **Domains.** A project with several domains (billing, inventory; or transport,
  presence) gets a `domains.md` map and one `kind: domain` note each, with a rule that
  makes the agent read it on entering the domain.
- **Existing docs are adopted, not copied.** A design doc or per-module notes file kept
  current becomes a `kind: pointer` note; keeping the doc current then satisfies the
  guard.
- **It can't drift silently.** `memory-drift-guard` blocks a commit that touches code
  covered by a note when the note isn't in the commit. `SKIP_MEMORY_CHECK=1` is for when
  the note was read against the diff and still holds.
- **It grows by use.** Install maps the minimum (non-negotiables, architecture, module
  map, domains). After that, `/cognisphere:update <area>` deepens one area when a real
  task enters it; Claude may run it itself, and still asks before writing.

## The vault

```
Agent/
├── 00 Home.md            entry point: reading order, ground rules, map
├── State/                Open Threads · Findings · History
├── Workflow/             Session Protocol · Vault Guide
├── Log/                  YYYY-MM-DD.md, one "## Session N" block per session
└── Scratch/              README.md + throwaway work
Human/                    your notes; the agent only reads them
```

**The vault holds only what nothing else holds.** The repo's state and history are in
git. Commands, conventions and area knowledge are in `AGENTS.md` and `.agents/`, which
load every session anyway. A code defect ends up in an issue. A copy of any of those in
the vault is read twice and goes stale the first time the original changes. What is left
is the agent's own: open threads (harness work, questions and decisions waiting on you),
findings (a defect waits there until you open its issue), events git doesn't record, the
session log and scratch work.

**Findings** — `~/Cognisphere/<project>/Agent/State/Findings.md` — is where the agent
writes what it notices outside its task (a bug, a risk, a smell, a missing test, an
improvement, an idea) the moment it notices it, without fixing it unasked:

```
### 3. [bug] retry loop ignores the timeout: `src/client.ts:88`
Seen 2026-10-26 at `a578366`, while adding the vault command.
<evidence> · <suggestion>
Status: open
```

Ask "known issues?" or "what would you improve?" and it reads this file first,
re-checks each open item against the code since its commit and says which commit the
answer stands at, rather than scanning the repo. You triage by telling the agent: an
item becomes an issue, goes into your plan, or is rejected with a reason; a closed one
stays struck through with its outcome, so a rejected suggestion doesn't come back. It
covers only the areas the agent has worked in: a log of what it saw, not an audit.

**Working style.** Install asks whether the agent is your **author** (writes code when
asked, proposes before large or risky changes) or your **tutor** (you write the code to
learn; it explains trade-offs, reviews and sketches diffs, and doesn't edit repo files
unless asked). The answer lives in `AGENTS.local.md`, so two people on one repo can
choose differently.

- **Seeded once.** After install the vault belongs to you and the agent; the plugin never
  maintains it. `/cognisphere:vault` re-seeds only missing notes.
- Every note ships complete: frontmatter, navigation line, sections, and at most a
  one-line hint comment (`<!-- … -->`), invisible in Obsidian's reading view.
- Install writes only what its run found: open questions into Open Threads, the defects
  and improvements it came across into Findings, and Session 1 of today's Log.
- `Workflow/Vault Guide.md` is the vault's rulebook. From then on the agent maintains and
  may restructure `Agent/` through its Session Protocol.
- When the repo keeps its own plan or progress log, the session ends there first, and
  the Log points to it rather than restating it.

## Commands

```
/cognisphere:install                 # harness + vault, asked in one round
/cognisphere:harness                 # only the versioned repo layer
/cognisphere:vault                   # only your vault and its local configuration
/cognisphere:update [area]           # maintains the harness; with an area, maps just that one
/cognisphere:read <note> [request]   # reads a vault note you copied in Obsidian
```

### `/cognisphere:install`

`/cognisphere:harness` then `/cognisphere:vault`, with their questions asked in one round
first: the repo language, the project name and vault path, the working style, and what
will be created. It always does both; to leave one half out, run the other command. Each
step creates only what is missing:

1. the `.agents/` structure, `AGENTS.md`, the symlinks and the `.gitignore` entries;
2. the memory catalog (it asks before writing the notes);
3. the rules (it asks the commit policy);
4. the vault under `~/Cognisphere/<project>/`;
5. the local configuration;
6. the run's open questions in Open Threads, the defects it came across in Findings, and
   Session 1 of the Log;
7. a report.

Restart the session afterwards so `CLAUDE.local.md` loads.

In a repo whose harness belongs to someone else, install stops and proposes
`/cognisphere:vault` instead.

### `/cognisphere:harness`

Steps 1–3 of install and its report: the versioned repo layer only. Nothing under
`~/Cognisphere/`, and no `AGENTS.local.md`, `CLAUDE.local.md` or `settings.local.json`.
The vault is personal: everyone on the repo decides for themselves, and
`/cognisphere:vault` adds it any time.

Run after `/cognisphere:vault` (a repo set up vault-only), it also moves the local
configuration over: the vault's `.claude/settings.local.json` is merged into
`.agents/settings.local.json` before `.claude` becomes the link, `## Repo layer` leaves
`AGENTS.local.md`, and the `.git/info/exclude` lines the new `.gitignore` entries cover
are removed. It asks first, and never touches the vault.

### `/cognisphere:vault`

Steps 4–6 of install and its report: only your vault and the local configuration that
points the agent at it, and never anything git tracks. It's the command for a teammate
joining a repo that already has the harness, for adding a vault after
`/cognisphere:harness`, and for a repo you shouldn't change.

Where the local files go depends on whose harness the repo has:

- **cognisphere's** (`.agents/rules/memory.md` names `/cognisphere:update`):
  `.agents/settings.local.json`, ignored by the `.gitignore` lines install committed.
- **someone else's, or none** (a company project with its own `.agents/`, another
  tool's harness): `.claude/settings.local.json` (inside the directory `.claude` links
  to, if it is a link), with all three files ignored through `.git/info/exclude`, which
  is never committed. `AGENTS.local.md` records it in `## Repo layer`, so
  `/cognisphere:update` only checks the vault and the local configuration. The guards
  still run, and `memory-drift-guard` still enforces the repo's own notes, if it has
  any.

Either way `git status` shows nothing new. It stops, writing nothing, if git tracks one
of those files.

### `/cognisphere:update [area]`

With no argument, reviews the versioned harness: structure, settings, memory, rules.
Index integrity and the anti-drift rules are the memory contract, so it restores them
without asking. Everything else is proposed, and written only on a yes. Then it
**checks** the vault and the local configuration and reports what is missing or points
elsewhere (no vault set up is a choice, not a finding), and checks `~/.claude/settings.json` for what would run the guards twice:
agent-kit or a second cognisphere enabled, a guard hook registered for the user. It
never writes to any of them. In an older vault, it reports the notes of the v0.1.0
layout (Current State, Working Agreement, Review Checklist, `Knowledge/`) with what to
move out before deleting them; it never deletes them itself.

With an area — a directory (`src/payments`), a module (`billing`) or a subject
(`authentication`) — it maps or deepens only that area: one note with `paths:`, its read
rule, an index line.

### `/cognisphere:read <note> [request]`

Takes what Obsidian copies, so you can hand the agent the note you are looking at: its
path relative to the open vault (`Human/draft.md`, or `<project>/Human/draft.md` when
`~/Cognisphere` itself is open). It reads the note from this project's vault, with its
embeds and the links its content depends on, one level deep. It checks what the note
says about the code against the code, then does the request
(`/cognisphere:read Human/draft.md plan phase 1`), or, with none, says what it read and
what the code contradicts, and asks. It never writes the note, and only you run it.

## Guards

All three are checks in one hook, `hooks/guard.sh`, run before every Bash call. They
fail open: an internal error never blocks the session.

- **`master-guard`** — on `master`/`main`, blocks anything that writes a commit there
  (`commit`, `cherry-pick`, `revert`, `am`, `rebase`), plus `git merge`,
  `git reset --hard` and any `push` that targets the protected branch. `--abort` /
  `--continue` on a stuck sequencer still go through.
- **`secret-guard`** — blocks a `git commit` whose content looks like a secret: a
  private-key header, a well-known token format (AWS/GitHub/Slack/GCP), or a `.env` or
  keystore (`.p12`/`.pfx`/`.jks`) being added.
- **`memory-drift-guard`** — blocks a `git commit` that touches code covered by a memory
  note (its `paths:` frontmatter) when the note is not in the same commit. For a
  `kind: pointer` note, its `doc:` counts too. Prefix `SKIP_MEMORY_CHECK=1` when the
  note still holds.

The versioned `settings.json` also denies the blanket `git add` forms (`-A`, `--all`,
`.`, `-u`) and allows the read-only git commands without prompting.

## Boundaries and their limits

- `Human/` is protected by a deny rule in `settings.local.json`
  (`Edit(~/Cognisphere/<project>/Human/**)`). It covers Claude's file tools, the Bash file
  commands Claude Code recognizes, and redirects. It does **not** cover arbitrary
  scripts (a `python -c` that opens the file); the sandbox covers those, if you turn it
  on.
- Only `Read` and `Edit` rules are used: `Write(...)` rules never match, because `Edit`
  rules cover the Write tool.
- **Folder trust.** When `.claude` is a symlink, Claude Code treats `settings.local.json`
  as supplied by the repo. Its allow rules and `additionalDirectories` apply only once
  you trust the folder; until then, reading the vault prompts. Deny rules always apply.

## Backups

**The vault is yours to back up.** Nothing under `~/Cognisphere/` is in git, and
cognisphere never syncs or copies it. Pick one:

- add `~/Cognisphere` to a sync client (Google Drive for desktop, Dropbox, OneDrive,
  iCloud Drive);
- Obsidian Sync or Syncthing;
- a scheduled `rsync` or `restic` copy.

Test a restore once. Sync clients may create conflict copies; merge them by hand. If the
folder goes missing, `/cognisphere:update` reports it and creates nothing. Restore it
from the backup, or run `/cognisphere:vault` to re-seed the notes.
`~/Cognisphere/README.md` repeats this.

## Windows

Works under Git Bash (its `perl` has `JSON::PP`), but the harness relies on symlinks
(`.claude`, `CLAUDE.md`, `CLAUDE.local.md`), and by default Git Bash's `ln -s` copies
instead and git checks links out as plain text files. Install retries each link with
`MSYS=winsymlinks:nativestrict`, which often works without admin; it stops only when
that fails too. For links that survive later checkouts, once per machine:

1. Turn on **Developer Mode** (Settings → System → For developers), so links need no admin.
2. `git config --global core.symlinks true`
3. Add `export MSYS=winsymlinks:nativestrict` to `~/.bashrc`, so `ln -s` makes real links.

Repos cloned before step 2 need `git checkout -- CLAUDE.md .claude` to turn the text
files back into links. When install had to fall back on the retry, its report lists
these steps as a follow-up.

## Coming from agent-kit

cognisphere is agent-kit v0.12.0 with seven skills collapsed into two, plus the vault and
`/cognisphere:read`. The guards and the five agents are the same, only renamed, so it
replaces agent-kit entirely. Keeping both would run every guard twice.

```
/plugin uninstall agent-kit@agent-kit
/plugin marketplace remove agent-kit
```

Then install cognisphere as in [Quick start](#quick-start), and in each project run
`/cognisphere:update`. It offers to remove old agent-kit entries from `settings.json`,
reports any agent-kit still enabled in `~/.claude/settings.json`, and replaces the
`agent-kit:memory` pointer in `rules/memory.md`. Run `/cognisphere:install` to add the
vault and the local configuration; the existing harness stays as it is.

| agent-kit | cognisphere |
|---|---|
| `scaffold`, `memory`, `rules` | `/cognisphere:install` |
| `update-all`, `update-hooks`, `update-memory`, `update-rules` | `/cognisphere:update` |
| `memory <area>`, `rules <area>` | `/cognisphere:update <area>` |

## Uninstall

```bash
claude plugin uninstall cognisphere@cognisphere
claude plugin marketplace remove cognisphere
```

What it wrote stays: `.agents/` and `AGENTS.md` in each repo (versioned, the project's
own), the local files, and `~/Cognisphere/`. Delete those by hand if you want them gone.

To pin a machine to a release instead:
`claude plugin marketplace add https://github.com/rockberpro/cognisphere.git#0.9.0`.

## Language

Everything in this repository is in English: code, docs, hook output. What the plugin
generates in a project's `.agents/` and `AGENTS.md` follows **that project's** language,
declared once in `AGENTS.md` (proposed at install, confirmed by you) and read from there
on every run. The vault and `AGENTS.local.md` are always English; domain terms stay as
the code names them. Filenames stay English everywhere.

## Not supported

- **Other agent CLIs** (Codex, Cursor, …). `.agents/` and `AGENTS.md` are tool-neutral and
  readable by any of them, but this plugin ships no manifests for them and is not tested
  with them.

## What is inside

- **`skills/`** — `harness`, `vault` and `update`, each running the steps in its
  `SKILL.md` and reading procedures from `procedures/` on demand (`scaffold`, `memory`,
  `rules`, `review-settings`, `review-memory`, `review-rules`, `vault`, `vault-check`);
  `install`, which runs `harness` then `vault`; `read`, with no procedure.
- **`hooks/`** — `guard.sh` and one test per guard.
- **`agents/`** — `cognisphere:explorer` (read-only investigator; the memory passes fan
  out to it), `cognisphere:planner` (ordered steps from an explorer report),
  `cognisphere:implementer` (one planned step, code plus the stale note),
  `cognisphere:test-runner` (runs the tests, returns only the failures) and
  `cognisphere:reviewer` (a diff against the project's own memory, rules and commit
  policy).
- **`scripts/`** — the deterministic steps, so the agent runs them instead of retyping
  them: `scaffold.sh`, `seed-vault.sh`, `configure.sh`, `names.sh`, `link.sh`,
  `repo-layer.sh` (moves a vault-only repo's local files over when the harness is added),
  `merge-json.pl` (adds missing settings entries, keeps key order), `check-links.pl`,
  `coupling.sh` (how often an area's commits already touch the doc a pointer note adopts),
  `user-settings.pl` (what in the user-level settings runs the guards twice).
- **`templates/`** — `settings.json`, `rules/memory.md` (the anti-drift rule),
  `settings.local.json` and `AGENTS.local.md` (the local configuration), and `vault/`
  (the vault README, `Human/README.md`, one template per `Agent/` note).
- **`evals/`** — `claude plugin eval` fixtures for the memory and rules passes.

Why the plugin is the way it is, and what was considered and rejected:
[docs/decisions.md](docs/decisions.md). Releasing and what belongs in the plugin:
[CONTRIBUTING.md](CONTRIBUTING.md).
