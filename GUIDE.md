# Cognisphere guide

The reference behind the [README](README.md): how each part works, what each command
does step by step, and the setup notes you need once.

- [The memory catalog](#the-memory-catalog)
- [The vault](#the-vault)
- [Commands](#commands)
- [Guards](#guards)
- [Boundaries and their limits](#boundaries-and-their-limits)
- [Backups](#backups)
- [Windows](#windows)
- [Uninstall](#uninstall)
- [Language](#language)
- [Not supported](#not-supported)
- [What is inside](#what-is-inside)

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
- **Domains.** A project with several business domains (billing, inventory; or
  transport, presence) gets a `domains.md` map and one note per domain (marked
  `kind: domain` in its frontmatter), with a rule that makes the agent read it on
  entering the domain.
- **Existing docs are adopted, not copied.** A design doc or per-module notes file kept
  current becomes a **pointer note** (`kind: pointer`): a short note that names the doc
  in `doc:` instead of repeating it. Keeping the doc current then satisfies the guard.
- **It can't drift silently.** `memory-drift-guard` blocks a commit that touches code
  covered by a note when the note isn't in the commit. `SKIP_MEMORY_CHECK=1` is for when
  the note was read against the diff and still holds.
- **It grows by use.** Install maps the minimum (non-negotiables, architecture, module
  map, domains). After that, `/cognisphere:update <module>` deepens one module (a
  directory, a named module or a feature that spans folders: `src/payments`, `billing`,
  `authentication`) when a real task
  enters it; Claude may run it itself, and still asks before writing.

## The vault

```
~/Cognisphere/
├── README.md                 backups, and what is where
├── Shared/                   your notes for every project; every agent reads, none writes
└── Projects/<project>/       one vault per repo
    ├── Agent/
    │   ├── 00 Home.md        entry point: reading order, ground rules, map
    │   ├── State/            Open Threads · Findings · History · Preferences
    │   ├── Workflow/         Session Protocol · Vault Guide
    │   ├── Log/              YYYY-MM-DD.md, one "## Session N" block per session
    │   └── Scratch/          the agent's output, one YYYY-MM-DD/ folder per day, kept
    └── Human/                your notes; this project's agent only reads them
```

Anything else you keep in `~/Cognisphere/` is yours alone: no agent is granted it.

**The vault holds only what nothing else holds.** The repo's state and history are in
git. Commands, conventions and area knowledge are in `AGENTS.md` and `.agents/`, which
load every session anyway. A code defect ends up in an issue. A copy of any of those in
the vault is read twice and goes stale the first time the original changes. What is left
is the agent's own: open threads (harness work, questions and decisions waiting on you),
findings (a defect waits there until you open its issue), how you want it to work, events
git doesn't record, the session log and scratch work.

`Scratch/` is the exception: it is the agent's workbench for what its work produces,
written freely (a plan before a multi-step edit, scripts, drafts and intermediate output,
dead ends ruled out during an investigation) in one folder per day. It holds output, not
the model's thinking aloud, and only output worth keeping: throwaway material (a test
repo, a download, build output) goes in a `mktemp -d` folder, out of your backups. A
note reads as the current state of its work: when a decision replaces part of a plan, the
agent rewrites that part in place and keeps what was dropped as one `Considered and
rejected` line, instead of stacking revisions you would have to merge by hand. Today's
folder is the work in flight; older ones are kept as the history of how the work went, and are never read as the current state. It takes what
Claude Code would otherwise keep in its session scratchpad and plans folder, and
`State/Preferences.md` takes what auto-memory would keep about you (corrections, approaches
you confirmed, how you like to work), loaded at every session start. So the project's
whole working state is in the vault: back up the vault, or open it in Obsidian, and you
have it.

### Findings

`~/Cognisphere/Projects/<project>/Agent/State/Findings.md` is where the agent writes
what it notices outside its task (a bug, a risk, a smell, a missing test, an
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

### Working style

Install asks whether the agent works on **auto** (you give the goal; it breaks it into
subtasks, decides, implements and verifies without asking at each step, and stops only
when the goal is unclear or before a destructive or outward-facing action), as your
**copilot** (you drive; it answers, reviews and suggests when asked, and writes the code
only for a task you hand over, then hands the wheel back) or as your **tutor** (you write
the code to learn; it explains trade-offs, reviews and sketches diffs, and doesn't edit
repo files unless asked). The texts are in `templates/styles/`. The answer lives in
`AGENTS.local.md`, so two people on one repo can choose differently, and each project
keeps its own. `/cognisphere:auto`, `/cognisphere:copilot` and `/cognisphere:tutor`
switch it (see § Commands).

### Who maintains it

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
/cognisphere:update [module | --note <path>]  # maintains the harness; with a module or note, just that one
/cognisphere:read <note> [request]   # reads a vault note you copied in Obsidian
/cognisphere:auto                    # working style: you give the goal, the agent drives
/cognisphere:copilot                 # working style: you drive, the agent helps
/cognisphere:tutor                   # working style: you write the code, the agent teaches
```

Each setup command also takes `--project <dir>` for a sub-project, e.g.
`/cognisphere:install --project frontend`. See § Sub-projects.

### `/cognisphere:install`

`/cognisphere:harness` then `/cognisphere:vault`, with their questions asked in one round
first: the repo language, the project name and vault path, the working style, and what
will be created. It always does both; to leave one half out, run the other command. Each
step creates only what is missing:

1. the `.agents/` structure, `AGENTS.md`, the symlinks and the `.gitignore` entries;
2. the memory catalog (it asks before writing the notes);
3. the rules (it asks the commit policy);
4. the vault under `~/Cognisphere/Projects/<project>/`, and `~/Cognisphere/Shared/`
   the first time;
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
  `/cognisphere:update` only checks the vault and the local configuration. cognisphere
  adds no guards there (D37): the repo's own harness runs whatever guards it carries,
  and only the vault's hooks, from the plugin, act for you.

Either way `git status` shows nothing new. It stops, writing nothing, if git tracks one
of those files.

### `/cognisphere:update [--project <dir>] [module | --note <path>]`

With no argument, reviews the versioned harness: structure, settings, memory, rules.
Index integrity and the anti-drift rules are the memory contract, so it restores them
without asking. Everything else is proposed, and written only on a yes.

Then it **checks**, without writing:

- the vault and the local configuration, reporting what is missing or points elsewhere
  (no vault set up is a choice, not a finding);
- `~/.claude/settings.json`, for what would run a guard twice: a plugin with the same
  guards enabled, a guard hook registered for the user on top of the repo's own;
- an older vault, reporting the notes of the v0.1.0 layout (Current State, Working
  Agreement, Review Checklist, `Knowledge/`) with what to move out before deleting
  them. It never deletes them itself.

With a module — a directory (`src/payments`), a named module (`billing`) or a feature
that spans folders (`authentication`) — it maps or deepens only that module: one note with `paths:`, its read
rule, an index line. With `--note <path>` instead (`--note .agents/memory/payments.md`), it
deepens just that note against the code its `paths:` cover, and that note's read rule.

### `/cognisphere:read <note> [request]`

Takes what Obsidian copies, so you can hand the agent the note you are looking at: its
path relative to the open vault (`Human/draft.md`, or `Projects/<project>/Human/draft.md`
and `Shared/conventions.md` when `~/Cognisphere` itself is open). It reads the note from
this project's vault or from `Shared/`, never from another project's folder, with its
embeds and the links its content depends on, one level deep. It checks what the note
says about the code against the code, then does the request
(`/cognisphere:read Human/draft.md plan phase 1`), or, with none, says what it read and
what the code contradicts, and asks. It never writes the note, and only you run it.

### `/cognisphere:auto`, `/cognisphere:copilot`, `/cognisphere:tutor`

Switch the working style of the project you run them in, from that reply on. Each
writes its text into `AGENTS.local.md` § Working style, the root's even from a
sub-project, since that is the file that loads, and records the switch in the vault's
Log when you have one. Lines of your own under the heading stay; a section holding only
text of your own is shown to you before anything replaces it. In a repo with no
`AGENTS.local.md` (harness only, no vault), it creates one with just that section, git
ignored. Only you run them: the agent never switches its own style. Installs before
v0.23.0 that chose **author** keep its text until you switch; `/cognisphere:update`
reports it.
## Sub-projects

A monorepo often gives each part its own instructions: `frontend/CLAUDE.md` with the
Nuxt conventions, `backend/CLAUDE.md` with Laravel's, each with its own `.claude/`.
Claude Code reads a `settings.json` only from the folder a session starts in, so a
session started in `frontend/` runs none of the root's settings or guards. Each
sub-project therefore gets its own harness, set up and maintained with `--project`:

```
/cognisphere:install --project frontend    # its harness, pointed at the root's vault
/cognisphere:harness --project backend     # its harness only
/cognisphere:vault --project backend       # its local configuration only
/cognisphere:update --project frontend     # maintains it
/cognisphere:update --project frontend src/pages   # maps a module inside it
```

```
projeto/
  AGENTS.md   CLAUDE.md -> AGENTS.md      # lists the sub-projects
  .agents/    .claude -> .agents
  frontend/
    AGENTS.md   CLAUDE.md -> AGENTS.md
    .agents/    .claude -> .agents        # its notes, rules, settings, guard copy
  backend/
    ...
```

- **Both layouts work.** A sub-project can be a folder of the root's repo, or a repo of
  its own inside the root's folder (a nested clone or a submodule); git tells which.
- **Its notes and rules** have globs relative to its own folder, as Claude Code reads a
  nested `.claude/rules/`. The root's notes don't cover a sub-project's folder.
- **The commit policy:** a sub-project in the root's repo links `rules/commit.md` to the
  root's; one with a repo of its own gets its own.
- **One vault**, the root's. In the root's repo, a sub-project needs no local file; with
  a repo of its own, it gets a `settings.local.json` pointing at the root's vault.
- **The drift guard** checks every note in the repo against a commit, from the root or
  from a sub-project, and follows `cd backend && git commit` into a nested repo.
- `/cognisphere:update` at the root lists the sub-projects and the folders that look
  like one (a `CLAUDE.md` or `.claude/` of their own, no `.agents/`). It never
  maintains them on its own.

- **Inside the vault, a tag.** What a sub-project's session adds to the Log, Open Threads
  and Findings carries its path from the root as an Obsidian tag (`#frontend`,
  `#apps/web`), and its Scratch notes go in `Scratch/<day>/<tag>/`. A session started in
  `frontend/` is shown only the threads tagged `#frontend` or with no sub-project's tag
  (it is told how many it left out), and the Stop hook asks for the tag when its Log
  entry lacks it. A session started at the root sees everything and tags by hand, as
  the Session Protocol says.

## Guards

All three are checks in one hook, run before every Bash call. It belongs to the repo,
not the plugin (D37): `/cognisphere:harness` copies the plugin's `hooks/guard.sh` to
`.agents/hooks/guard.sh` and registers it in `.agents/settings.json`, both versioned, so
the guards run for everyone who works on the repo with Claude Code, plugin or not. The
harness asks which checks to carry, all three checked by default; a check left out is a
flag on the registered command (`--no-master`, `--no-secret`, `--no-memory-drift`),
which the team can change in a PR. `/cognisphere:update` refreshes the copy and never
rewrites the registration. The plugin itself runs no guard. They fail open: an internal
error never blocks the session.

- **`master-guard`** — on `master`/`main`, blocks anything that writes a commit there
  (`commit`, `cherry-pick`, `revert`, `am`, `rebase`), plus `git merge`,
  `git reset --hard` and any `push` that targets the protected branch. `--abort` /
  `--continue` on a stuck sequencer still go through.
- **`secret-guard`** — blocks a `git commit` whose content looks like a secret: a
  private-key header, a well-known token format (AWS, GitHub, Slack, GCP, GitLab, Anthropic, OpenAI,
  Stripe live keys), or a `.env` or keystore (`.p12`/`.pfx`/`.jks`) being added.
- **`memory-drift-guard`** — blocks a `git commit` that touches code covered by a memory
  note (its `paths:` frontmatter) when the note is not in the same commit. For a
  pointer note, its `doc:` counts too. Prefix `SKIP_MEMORY_CHECK=1` when the note still
  holds.

The vault's hooks come from the plugin and act only where your `AGENTS.local.md` names a
vault: nothing in the repo registers them, so a teammate is never affected. One runs
when the agent stops:

- **`session-log`** — `hooks/session-log.sh`, a Stop hook. When the session changed
  files, made a commit or touched a vault `State/` note, and no file in the vault's
  `Log/` changed, it blocks the stop once and asks for Session Protocol § End: the
  `## Session N` entry and Open Threads. The vault path comes from `AGENTS.local.md`.
  The reason carries the entry to paste: numbered after today's note, tagged in a
  sub-project, with Changed already filled in (the session's commits, "uncommitted",
  the vault files it wrote) and Not verified from the transcript's last test run
  ("no tests ran this session", "the last test run (`npm test`, 14:32) failed", or
  the files that changed after it), so the agent writes only Asked, Found, Did and Next
  and checks the rest. The hook never writes the Log itself.
  A Log written early in the session (a correction recorded as it happened) covers only
  the work before it: once 3 or more repo files changed after its newest write, the
  stop blocks again. A reply that only pauses for you just stops again, and the same
  changes aren't reported twice. When a reply says something outside the task is
  wrong ("unrelated, but the retry loop never backs off", "a pre-existing bug") and
  `State/Findings.md` wasn't written since, it blocks once, quoting the sentence and
  handing over the item's heading, numbered, with the Seen line's date and sha. Both
  readings of the transcript are heuristics: a test command no pattern knows reads as
  "no tests ran", and a finding put in other words is missed.
  It also blocks once when the session touched 3 or more repo files (committed or
  not) and nothing in `Scratch/` changed, or when 3 or more changed after the newest
  Scratch write, asking for the working notes. And it catches what `scratch-redirect`
  can't see, a write through Bash into Claude Code's own stores: a file modified this
  session in the session's scratchpad or the project's auto-memory folder, which it asks
  the agent to move into the vault.

And four more, from the plugin, in a project with a vault only:

- **`scratch-first`** — `hooks/scratch-first.sh`, a PostToolUse hook on Edit, Write,
  MultiEdit, NotebookEdit and Bash. After an edit of a repo file, reminds the agent in context
  to write its note in a `Scratch/YYYY-MM-DD/` day folder when the session has none, and
  again once 3 or more repo files (committed or not) changed since the newest Scratch
  write. It never blocks, and says each thing once: the next reminder waits until the
  agent writes in Scratch and falls behind again. Edits outside the repo pass. A Bash
  call names no file, so after one it asks git which repo files the session changed.

- **`scratch-redirect`** — `hooks/scratch-redirect.sh`, a PreToolUse hook on the same
  tools. Refuses a write to Claude Code's session scratchpad (a `scratchpad/` folder
  under `claude*` in the temp dir) or to auto-memory
  (`~/.claude/projects/*/memory/`, or under `CLAUDE_CONFIG_DIR`), and says where it
  goes in the vault instead. Writes through Bash aren't seen here; `session-log` finds
  them at the stop.

- **`plan-mirror`** — `hooks/plan-mirror.sh`, a PostToolUse hook on Write, Edit and
  MultiEdit. Copies a plan-mode plan (`~/.claude/plans/*.md`) to
  `Scratch/<today>/plan <name>.md` on every write, so plan mode keeps working and the
  plan still ends up in the vault. A custom `plansDirectory` isn't followed.

- **`session-start`** — `hooks/session-start.sh`, a SessionStart hook. Loads `00 Home`,
  Open Threads and the tail of the latest Log note into the session's context, each
  capped, lists today's `Scratch/` notes and any file loose outside a day folder, names
  the newest earlier day folder as history, and tells the agent to keep its working
  state in the vault rather than in Claude Code's own stores.

The versioned `settings.json` also denies the blanket `git add` forms (`-A`, `--all`,
`.`, `-u`) and allows the read-only git commands without prompting.

## Boundaries and their limits

- `Human/` and `Shared/` are protected by deny rules in `settings.local.json`
  (`Edit(~/Cognisphere/Projects/<project>/Human/**)`, `Edit(~/Cognisphere/Shared/**)`).
  They cover Claude's file tools, the Bash file commands Claude Code recognizes, and
  redirects. They do **not** cover arbitrary scripts (a `python -c` that opens the
  file); the sandbox covers those, if you turn it on.
- Other projects' vaults are kept out by granting nothing over them: no `Read` rule
  covers `~/Cognisphere` or `Projects/` as a whole. Reading one still prompts you.
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

## Uninstall

```bash
claude plugin uninstall cognisphere@cognisphere
claude plugin marketplace remove cognisphere
```

What it wrote stays: `.agents/` and `AGENTS.md` in each repo (versioned, the project's
own), the local files, and `~/Cognisphere/`. Delete those by hand if you want them gone.

To pin a machine to a release instead, add the marketplace at that release's tag:
`claude plugin marketplace add https://github.com/rockberpro/cognisphere.git#<version>`.

## Language

Everything in this repository is in English: code, docs, hook output. What the plugin
generates in a project's `.agents/` and `AGENTS.md` follows **that project's** language,
declared once in `AGENTS.md` (proposed at install, confirmed by you) and read from there
on every run. The vault and `AGENTS.local.md` are always English; domain terms stay as
the code names them. Filenames stay English everywhere.

## Not supported

- **A root that is not a git repo**: a plain folder holding `frontend/` and `backend/`
  repos. Each command needs a git root to start from (D38).
- **Other agent CLIs** (Codex, Cursor, …). `.agents/` and `AGENTS.md` are tool-neutral and
  readable by any of them, but this plugin ships no manifests for them and is not tested
  with them.

## What is inside

- **`skills/`** — `harness`, `vault` and `update`, each running the steps in its
  `SKILL.md` and reading procedures from `procedures/` on demand (`scaffold`, `memory`,
  `rules`, `review-settings`, `review-memory`, `review-rules`, `vault`, `vault-check`);
  `install`, which runs `harness` then `vault`; `read`, with no procedure; `auto`,
  `copilot` and `tutor`, which share the `style` procedure.
- **`hooks/`** — `guard.sh` (the source `/cognisphere:harness` copies into each repo; the
  plugin doesn't run it), and the vault's hooks the plugin runs: `session-log.sh`, `session-start.sh`, `scratch-first.sh`, `scratch-redirect.sh`, `plan-mirror.sh`, with `vault-of.sh` (the nearest `AGENTS.local.md`'s vault, for all five), and one test per guard and hook.
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
  `user-settings.pl` (what in the user-level settings runs a guard twice), `guards.sh`
  (copies the guard into a repo and registers it with the team's flags), `target.sh`
  (the root, or the sub-project `--project` names, and its layout),
  `subprojects.sh` (the sub-projects below the root, and the candidates) and `style.sh`
  (the working-style switch).
- **`templates/`** — `settings.json`, `rules/memory.md` (the anti-drift rule),
  `settings.local.json` and `AGENTS.local.md` (the local configuration), `styles/` (the
  three working styles), and `vault/`
  (the root and `Shared/` READMEs, `Human/README.md`, one template per `Agent/` note).
- **`evals/`** — `claude plugin eval` fixtures for the memory and rules passes.

Why the plugin is the way it is, and what was considered and rejected:
[docs/decisions.md](docs/decisions.md). Releasing and what belongs in the plugin:
[CONTRIBUTING.md](CONTRIBUTING.md).
