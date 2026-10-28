# Changelog

What changed in each release of cognisphere. Versions follow
[semver](https://semver.org/); the reasoning behind each change is in
[docs/decisions.md](docs/decisions.md), referenced as `Dnn`.

## 0.23.3 — 2026-10-28

### Added

- `/cognisphere:update --catalog` reviews just the memory catalog: index, anti-drift
  rule, stale notes, globs, domain declarations, with the same ask-before-writing split
  as the full review (D49). The read rules the notes owe are brought in line too, so a
  fixed glob never leaves its rule behind. Settings, the other rules, the vault and the
  configuration are skipped.

## 0.23.2 — 2026-10-28

### Added

- `/cognisphere:update --index` repairs just the memory index, `MEMORY.md`: merge-conflict
  markers, broken links, notes with no line or no way back (D48). No other pass runs.
  `--note .agents/memory/MEMORY.md` now points to it.

### Fixed

- The memory review resolves merge-conflict markers in `MEMORY.md` without asking, as
  part of index integrity: both sides' lines are kept, one per note (D48). It had no step
  for them. A note with conflict markers is a proposed fix, its sides read against the
  code.

## 0.23.1 — 2026-10-28

### Added

- `/cognisphere:update --note <path>` deepens a single memory note
  (`/cognisphere:update --note .agents/memory/payments.md`): its `paths:` are the module, and
  only that note and its read rule are touched (D47). After `--project <dir>`, the path
  may be relative to the sub-project's folder.

## 0.23.0 — 2026-10-28

### Added

- `/cognisphere:auto`, `/cognisphere:copilot` and `/cognisphere:tutor` switch the
  project's working style in `AGENTS.local.md`, from that reply on. Lines of your own
  under § Working style stay; a section of your own is shown before it is replaced. A
  harness-only repo gets an `AGENTS.local.md` with just that section, git ignored.
- Seeded vaults name the switches in Home and the Vault Guide. Existing vault notes
  aren't rewritten.

### Changed

- The working styles are **auto**, **copilot** and **tutor** (D46). Auto replaces
  author: the agent takes a goal, breaks it into subtasks, decides, implements and
  verifies without asking at each step, and stops only when the goal is unclear or before
  a destructive or outward-facing action. The texts live in `templates/styles/`.
- `/cognisphere:vault` (and install) asks auto, copilot or tutor.
- `/cognisphere:update` reports an `AGENTS.local.md` still holding the Author text.

## 0.22.0 — 2026-10-27

### Changed

- The Stop hook reads the session's transcript (D45). The Log entry it hands over has
  Not verified filled in from the last test run, as a sentence: no tests ran, the last
  run failed, or which files changed after it. A refused call, a heredoc or a commit
  message that mentions a test command doesn't count as a run.
- A reply that says something outside the task is wrong ("unrelated, but the retry
  loop never backs off") with nothing written in `State/Findings.md` since now blocks
  the stop once, quoting the sentence and handing over the item's numbered heading and
  its Seen line with today's date and HEAD. The hook still never writes the vault.

## 0.21.0 — 2026-10-27

### Changed

- The Stop hook's request for the end-of-session Log entry carries the entry itself
  (D44): `## Session N` numbered after today's note (tagged in a sub-project), the six
  Session Protocol fields, and Changed filled in from git and the vault (the session's
  commits, "uncommitted", the vault files it wrote). The agent pastes it and writes
  the rest; the hook still never writes the Log.

## 0.20.0 — 2026-10-27

### Changed

- The vault's checks follow the work, not the session start (D43). A Log entry written
  early, such as a correction recorded as it happened, no longer silences the
  end-of-session check: once 3 or more repo files changed after the newest Log write,
  the Stop hook asks again. The same goes for `Scratch/`: a note 3 files behind the work
  gets a block at the stop, not only `scratch-first`'s reminder.
- The Stop hook catches writes into Claude Code's own stores made through Bash, which
  `scratch-redirect` can't see: a file modified this session in the session's
  scratchpad or the project's auto-memory folder is listed for the agent to move into
  the vault.
- `scratch-first` also runs after Bash calls, asking git which repo files the session
  changed, so an edit made with `sed -i` or a heredoc gets the same reminder.
  The plugin's hooks update with the plugin; to get the reworded template lines, copy
  them from `templates/AGENTS.local.md`, the Scratch README and the Vault Guide by hand.

## 0.19.0 — 2026-10-27

### Changed

- A Scratch note reads as the current plan (D42): when a decision replaces part of it,
  the agent rewrites that part in place and keeps what was dropped as one line under
  `Considered and rejected`, with why, instead of appending revisions. `AGENTS.local.md`,
  the Scratch README, the Session Protocol, the Vault Guide and GUIDE.md say so;
  `/cognisphere:update` reports an `AGENTS.local.md` without the line. Existing vault
  notes aren't rewritten: copy the Scratch README, Session Protocol and Vault Guide
  lines by hand if you want them.

## 0.18.0 — 2026-10-27

### Changed

- `secret-guard` also catches GitLab (`glpat-`, `gldt-`, `glrt-`, `glptt-`), Anthropic
  (`sk-ant-`), OpenAI (`sk-proj-`, `sk-svcacct-`, `sk-admin-`, legacy) and Stripe live
  (`sk_live_`, `rk_live_`) tokens (D40). Repos pick it up with `/cognisphere:update`,
  which refreshes their copy of `guard.sh`.
- `master-guard` suggests `<type>/<description>` branch names (`feat/login-form`), not
  `<type>_<scope>_<description>`, and no longer blocks a push of a branch named after
  main, such as `fix/main` (D41).

## 0.17.0 — 2026-10-27

### Added

- A third working style, **copilot** (D39): the maintainer drives, the agent helps when
  asked, and it writes the code only for a task the maintainer hands over, then hands
  the wheel back. `/cognisphere:install` and `/cognisphere:vault` offer it next to
  author and tutor.

## 0.16.0 — 2026-10-27

### Added

- The vault tells sub-projects apart (D38, phase 2). A session started in a sub-project
  gets only the Open Threads tagged with it (`#frontend`, `#apps/web`) or with no
  sub-project's tag, told how many were left out; keeps its Scratch notes in
  `Scratch/<day>/<tag>/` (`scratch-first`, `scratch-redirect`, `plan-mirror`); and is
  asked by the Stop hook to tag its Log entry. The Session Protocol and the Vault Guide
  say how to tag; `/cognisphere:update` reports a vault whose Session Protocol predates
  it, when the repo has sub-projects.

## 0.15.0 — 2026-10-27

### Added

- Sub-projects: `/cognisphere:install`, `harness`, `vault` and `update` take
  `--project <dir>` to set up or maintain the harness of a folder below the root
  (a monorepo's `frontend/`, `backend/`), whether it is a folder of the root's repo or a
  repo of its own. Claude Code reads `settings.json` only from the folder a session
  starts in, so a session started in a sub-project used to run without the root's deny
  list and guards (D38).
- `scripts/target.sh` resolves `--project` and its layout; `scaffold.sh`, `guards.sh`,
  `names.sh` and `configure.sh` take the flag. `scripts/subprojects.sh` lists the
  sub-projects and the folders that look like one, for `/cognisphere:update` (D38).

### Changed

- `memory-drift-guard` checks every `.agents/memory/` in the commit's repo, each note's
  globs relative to its own folder, and follows a leading `cd <dir> &&` as it follows
  `git -C` (D38).
- `/cognisphere:update`'s argument is `<module>`, not `<area>`: a directory, a named
  module or a feature that spans folders. The anti-drift rule's last line says what it
  is and does; `/cognisphere:update` replaces the old pointer in existing repos.
- The vault hooks find the nearest `AGENTS.local.md` from the session's repo upwards,
  so a sub-project that is a repo of its own uses the root's vault (D38).

## 0.14.0 — 2026-10-26

### Added

- A PreToolUse hook, `scratch-redirect`: in a project with a vault, it refuses writes to
  Claude Code's session scratchpad and auto-memory and names the vault note to use
  instead, so the project's working state is all in the vault (D36).
- A PostToolUse hook, `plan-mirror`: in a project with a vault, it copies each plan-mode
  plan to `Scratch/<today>/plan <name>.md` on every write (D36).
- A seeded note, `State/Preferences.md`: how the maintainer wants the agent to work and
  what to know about them, the vault's home for what auto-memory kept. `session-start`
  loads it, and `scratch-redirect` points auto-memory writes to it (D36).
- `session-start` lists files left in the project's Claude Code auto-memory folder, for
  the agent to move into the vault; `/cognisphere:update` reports them (D36).
- `scripts/guards.sh`: copies the guard to `.agents/hooks/guard.sh` and registers it in
  `.agents/settings.json`, with a flag per check the team turned off (D37).
- `guard.sh` reads `--no-master`, `--no-secret` and `--no-memory-drift` from its command
  line (D37).

### Changed

- `Scratch/` keeps one folder per day, `Scratch/YYYY-MM-DD/`, and day folders stay after
  the session as history; only today's is current. Notes are no longer deleted (D36).
- `Scratch/` is described as the agent's workbench for what its work produces, not as
  "working memory": output, not thinking aloud, and only output worth keeping. Throwaway
  material (a test repo, a download, build output) goes in a `mktemp -d` folder (D36).
- **The guards belong to the repo.** The plugin no longer runs `guard.sh`:
  `/cognisphere:harness` copies it into `.agents/hooks/` and registers it in
  `.agents/settings.json`, both versioned, after asking which checks to carry (all three
  by default), so they run for the whole team with or without the plugin.
  `/cognisphere:update` refreshes the copy and, in a repo set up before this version,
  asks the guard question, since the guards stopped running there (D37).
- `scratch-first` is a PostToolUse reminder and never blocks: after a repo edit with no
  note in a day folder this session, or with the note 3 or more repo files behind, it
  tells the agent once (D36, D37).
- `merge-json.pl` adds a missing object entry to an array, compared by content (D37).
- `session-start` lists today's Scratch notes and loose files outside a day folder,
  names the newest earlier day folder as history, and tells the agent to keep its
  working state in the vault rather than Claude Code's own stores (D36).
- `scratch-first`, `scratch-redirect` and `plan-mirror` normalise paths with `cygpath`
  when it exists, so they also fire under Git Bash on Windows.
- `/cognisphere:update` reports an `AGENTS.local.md` with the v0.13.0 Scratch lines.
  Existing vault notes aren't rewritten: run `/cognisphere:vault` to seed
  `State/Preferences.md`, copy the Home, Scratch README, Session Protocol and Vault Guide
  changes by hand if you want them, and move loose Scratch notes into day folders.

## 0.13.0 — 2026-10-26

### Added

- A SessionStart hook, `session-start`: in a project with a vault, it loads `00 Home`,
  Open Threads and the tail of the latest Log note into the session's context, and
  lists any `Scratch/` file an earlier session left behind (D35).
- A PreToolUse hook, `scratch-first`: in a project with a vault, it refuses an Edit,
  Write, MultiEdit or NotebookEdit of a repo file until the session has written a note
  in `Scratch/`, so the plan comes before the code. Edits made through Bash aren't
  seen (D35).

### Changed

- `Scratch/` is now the agent's working memory: written freely, exempt from "only what
  nothing else holds", emptied at session end after promoting what matters.
  `AGENTS.local.md` gives it set moments: before the first edit of a multi-step task,
  before a long investigation, and a Log or Open Threads entry when the maintainer
  corrects or decides something (D35).
- The `session-log` Stop hook also blocks once when the session touched 3 or more repo
  files and wrote nothing in `Scratch/` (D35).
- `/cognisphere:update` reports an `AGENTS.local.md` without the Scratch lines. Existing
  vault notes aren't rewritten: copy the Scratch README, Session Protocol and Vault
  Guide changes by hand if you want them.

## 0.12.0 — 2026-10-26

### Added

- A Stop hook, `session-log`: in a project with a vault, when the session changed files,
  made a commit or touched a `State/` note and the vault's `Log/` has nothing new, it
  blocks the stop once and asks for the end-of-session entry. Stopping again goes
  through, and the same changes aren't reported twice (D34).

### Changed

- The README is now a short introduction (problem, quick start, a session end to end,
  one summary per part), and the reference moved to the new [GUIDE.md](GUIDE.md): every
  command step by step, the guards and their limits, backups, Windows, uninstall,
  language and the repository's contents (D33).
- The README presents the vault as a PKM (Personal Knowledge Management) system: an
  Obsidian AgentOS in plain Markdown that doesn't need Obsidian.
- Symlink failures on Windows point at `GUIDE.md § Windows`.

## 0.11.0 — 2026-10-26

### Changed

- **Vaults moved** from `~/Cognisphere/<project>/` to
  `~/Cognisphere/Projects/<project>/`, so the root no longer mixes generated vaults with
  your own folders. A vault at the old path isn't moved for you: `/cognisphere:update`
  reports the move, and `/cognisphere:vault` stops instead of seeding an empty vault
  beside it (D32).

### Added

- `~/Cognisphere/Shared/` for notes that serve every project: each project's agent may
  read it and is denied writing it. Nothing grants the root, `Projects/` or another
  project's folder.
- `/cognisphere:read` resolves `Projects/<project>/`, `<project>/` and `Shared/` paths,
  and refuses other projects' folders.

## 0.10.1 — 2026-10-26

### Fixed

- Skill descriptions no longer show `&lt;project&gt;` in the skill picker.

## 0.10.0 — 2026-10-26

### Added

- `/cognisphere:harness` sets up only the versioned repo layer, and
  `/cognisphere:vault` only the vault and its local configuration.
  `/cognisphere:install` runs both, asking their questions in one round (D31).
- Running `/cognisphere:harness` in a vault-only repo moves the local configuration
  over to `.agents/`.

### Changed

- No `## Agent workspace` in `AGENTS.local.md` means no vault: `update` and `read` skip
  the vault instead of reporting it missing.
- The README was rewritten around what cognisphere solves; the release gate moved to
  `CONTRIBUTING.md`.

### Removed

- Install's "leave the repo layer untouched" question (from 0.9.0): run
  `/cognisphere:vault` instead.

## 0.9.0 — 2026-10-26

### Added

- Install can leave the repo layer untouched, for repos whose harness belongs to
  someone else: local files go to `.claude/` and are ignored through
  `.git/info/exclude`, so `git status` shows nothing new (D30).
- Install compares `git status` before and after the run and reports any new line.

## 0.8.0 — 2026-10-26

### Added

- `/cognisphere:read <note> [request]` reads a vault note by the path Obsidian copies,
  with its embeds and links one level deep, checks it against the code, then does the
  request. It never writes the note (D28).

## 0.7.0 — 2026-10-26

### Added

- `Agent/State/Findings.md`: the agent records bugs, risks, smells, missing tests and
  ideas it notices outside its task, each anchored to a commit, and reads it first when
  asked for known issues (D27).

## 0.6.0 — 2026-10-26

### Added

- `/cognisphere:update` checks `~/.claude/settings.json` for what would run the guards
  twice: a second plugin with the same guards, cognisphere enabled more than once, a
  guard hook registered for the user. It never writes that file (D26).

## 0.5.0 — 2026-10-26

### Changed

- The agent keeps the vault up to date at the end of each session, and defers to the
  repo's own plan or progress log when there is one (D25).
- Install reports how much of the code the drift guard covers.

### Fixed

- Merging settings keeps key order and number form.

## 0.4.0 — 2026-10-25

### Added

- Install's mechanical steps ship as scripts in `scripts/` (scaffold, seed the vault,
  configure, links, settings merge, link check), with a self-test (D23, D24).
- Pointer notes (`kind: pointer`) adopt an existing doc instead of copying it; the drift
  guard accepts a commit that updates the doc.

### Fixed

- On Windows, links retry with `MSYS=winsymlinks:nativestrict` before stopping, and the
  vault path uses the `C:/` form.

## 0.3.0 — 2026-10-25

### Added

- Windows support under Git Bash (D22).

### Changed

- Install and update are the `/plugin` commands inside Claude Code.

### Fixed

- Install stops when `ln -s` copies instead of linking.

## 0.2.0 — 2026-10-25

### Added

- MIT license.

### Fixed

- The vault is seeded only with what git and the repo don't already hold.

## 0.1.0 — 2026-10-25

First release: the `.agents/` harness (memory catalog, rules, settings), the
`master-guard`, `secret-guard` and `memory-drift-guard` hooks, the per-project vault
with `Agent/` and `Human/`, `/cognisphere:install` and `/cognisphere:update`, and the
explorer, planner, implementer, test-runner and reviewer agents.
