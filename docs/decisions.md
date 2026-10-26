# Design decisions

Why cognisphere is the way it is. Point-in-time, ADR-style: an entry is never rewritten.
Reversing a decision adds a new entry, and the old one only gains a
"Superseded by D<n>" line.

Cognisphere joins two layers: the versioned harness in the repo (agent-kit's `.agents/`:
memory catalog, rules, settings, guards) and an unversioned per-project vault outside it
(`~/Cognisphere/<project>/`, with `Agent/` for the agent and `Human/` for the
maintainer), tied together by a gitignored local configuration.

---

## D1. The vault path is fixed at `~/Cognisphere/<project>/`

*2026-10-25, v0.1.0*

**Decision.** The vault lives at `~/Cognisphere/<project>/`, capitalized and visible in
the home folder. There is no setting to change it. `<project>` is the basename of the
*main* worktree
(`basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`),
so all worktrees of a repo share one vault. If the folder already exists and this repo's
local configuration does not point at it, install asks: reuse it, or pick another name.

**Why.** A fixed, visible path is one less thing to configure, to get wrong, or to
explain. Anyone can find their vaults, and so can any backup tool. Deriving the name from
the main worktree keeps one project's history in one place, whichever worktree a session
runs in. Asking on a name clash prevents two repos with the same basename from silently
sharing a vault.

**Rejected.** A configurable path (more surface, and nothing needed it). The spec's
`~/Obsidian/Vaults/Cognisphere/Projects/<p>` layout (D14). Naming the vault after the
current worktree, which would split one project's history across worktrees.

## D2. `Agent/` is scaffolded from one template per note

*2026-10-25, v0.1.0*

Superseded by D21.

**Decision.** `Agent/` is seeded from one template per note of the Vault Guide's layout:
`00 Home.md` plus `State/`, `Workflow/`, `Knowledge/`, `Log/` and `Scratch/`. Each
template has its frontmatter, navigation line and section headings. Each section carries
a one-line hint comment (`<!-- … -->`) naming its source and the rule against invention:
what no source says stays *unknown* or *not verified*. Templates carry `status: skeleton`
until filled; the hints stay after filling. From then on the agent maintains and may
restructure `Agent/` through its Session Protocol, logging the change; the plugin never
maintains it.

**Why.** An agent left to build a workspace invents both the structure and, worse, the
content. A skeleton gives it a structure to work in, and the hints tie every section to
a real source, so filling becomes condensing rather than writing. Hints are invisible in
Obsidian's reading view, so they cost nothing to keep and guide later sessions.
`status: skeleton` makes an unfilled note detectable by the next session and by `update`.

**Rejected.** A fixed, pre-written `00 Home.md` (D17). Letting the agent design the
layout freely.

## D3. The plugin seeds the vault and never maintains it

*2026-10-25, v0.1.0*

**Decision.** Vault files belong to the human and the agent. `install` only creates what
is missing under `~/Cognisphere/` and never modifies an existing file. `update` is
read-only there: it reports a missing vault folder or note (a lost backup, a broken
sync) and notes still at `status: skeleton`.

**Why.** After the first session the vault is the agent's working memory and the
maintainer's notes. Any automatic rewrite would destroy state that exists nowhere else,
since the vault is not in git. Reporting rather than recreating also stops a missing
folder (a sync gone wrong) from being papered over with an empty skeleton.

**Rejected.** `update` writing to the vault (D18).

## D4. The local configuration is personal; `update` only checks it

*2026-10-25, v0.1.0*

**Decision.** `update` verifies that `.agents/settings.local.json` and `AGENTS.local.md`
point at `~/Cognisphere/<project>`, and that `CLAUDE.local.md` links to
`AGENTS.local.md`. It reports any mismatch with the expected value and never edits
these files. The user fixes them by hand, or re-runs `/cognisphere:install` for a
missing one; install only creates what is missing.

**Why.** These files are gitignored and personal: they may hold the maintainer's own
permissions and instructions next to the vault entries. A mismatch can be deliberate (a
renamed project, a vault kept elsewhere). The plugin cannot tell, so it says what it
expected and leaves the decision to the person who owns the file.

**Rejected.** `update` repointing the configuration (D18).

## D5. `update` enforces the memory contract

*2026-10-25, v0.1.0*

**Decision.** Index integrity and the anti-drift rules are mandatory. When missing or
broken, they are written into `.agents/` without asking, and the report lists them.
Index integrity means every link in `MEMORY.md` resolves, every note has an index line,
and every note links back. The anti-drift rules are `rules/memory.md` plus a read rule
for every note that owns an area. Every other memory and rules finding is proposed and
written only on a yes, as in agent-kit.

**Why.** These pieces carry no policy, only the mechanics that keep the catalog
readable and in sync with the code. An orphan note is never found, and a note without
its read rule is never read before the first wrong edit. Asking about them adds a
question with only one sensible answer. Everything that involves judgement (a stale
note, a too-broad glob, a translation) stays the user's call.

**Rejected.** Asking before every fix, agent-kit's behaviour for these checks.

## D6. Language: the vault is English, the harness follows the project

*2026-10-25, v0.1.0*

**Decision.** The vault and `AGENTS.local.md` are in English, following the Agent
Guide's conventions and the spec's example, with domain terms kept as the code names
them. The versioned harness (`.agents/`, `AGENTS.md`) follows the project's declared
language, as in agent-kit, settled once in `scaffold.md` § Language.

**Why.** The harness is shared with a team that reads it in its own language. The vault
is a personal workspace whose structure and hints the plugin ships, and one language
keeps the templates, the Vault Guide and the checks aligned.

**Rejected.** Translated vault files (D16).

## D7. The working style is asked once, at install

*2026-10-25, v0.1.0*

**Decision.** Install asks whether the agent is an **author** or a **tutor**. The answer
is written into `AGENTS.local.md` § Working style and the Working Agreement's Roles. Both
texts are defined once, in `procedures/vault.md`:

- **Author:** "The agent writes and edits code when asked, following the project's
  rules, and proposes before large or risky changes."
- **Tutor, not author:** "The maintainer writes the code to learn. Explain trade-offs,
  review, catch what a second reviewer would, sketch diffs — but the maintainer
  implements. Don't edit repo files unless explicitly asked."

**Why.** The role changes how every session behaves, and it is personal: two people on
one repo can want different ones. So it belongs in the local file, not the versioned
harness. With one definition, the two places that quote it never drift apart.

**Rejected.** A fixed tutor mode, the spec's default. Asking again on every update.

## D8. `AGENTS.local.md` gets a `CLAUDE.local.md` bridge

*2026-10-25, v0.1.0*

**Decision.** `CLAUDE.local.md` is a symlink to `AGENTS.local.md`, mirroring
`CLAUDE.md -> AGENTS.md`. Both files go in the root `.gitignore`. `AGENTS.local.md`
holds the absolute vault path, because the Read tool needs absolute paths;
`settings.local.json` uses `~/` paths.

**Why.** No tool reads `AGENTS.local.md` natively, and Claude Code loads
`CLAUDE.local.md`. A symlink keeps one source of truth under the tool-neutral name,
the same convention the repo already uses.

**Rejected.** Writing the instructions directly into `CLAUDE.local.md`, which breaks the
`AGENTS.*` convention. Using `~` in `AGENTS.local.md`.

## D9. Backup advice lives in three places

*2026-10-25, v0.1.0*

**Decision.** Backups are explained in `~/Cognisphere/README.md` (created once, at the
vault root), in a Backups section of the plugin README, and in one line of
`Human/README.md`.

**Why.** The vault is not in git and the plugin never syncs it, so a lost disk loses it.
The warning has to sit where each reader looks: at install time (the README), in the
folder itself (the vault README), and next to the maintainer's own notes.

**Rejected.** Built-in sync or backup. That is out of scope, and many good tools already
do it.

## D10. agent-kit's guards and five subagents are ported

*2026-10-25, v0.1.0*

**Decision.** `master-guard`, `secret-guard`, `memory-drift-guard` and the explorer,
planner, implementer, test-runner and reviewer agents are copied from agent-kit v0.12.0.
Only names change. cognisphere fully replaces agent-kit, and `install.sh` warns if both
are installed.

**Why.** They are tuned and tested. A full replacement means one plugin to install,
and no guard runs twice.

**Rejected.** Depending on agent-kit as a second plugin. Rewriting the guards.

## D11. `update [area]` keeps agent-kit's grow-by-use mapping

*2026-10-25, v0.1.0*

**Decision.** The optional text after `/cognisphere:update` is an area: a directory
(`src/payments`), a module (`billing`) or a subject (`authentication`). It maps or
deepens only that area: one note with `paths:`, its read rule, and an index line. Claude
may run it itself when a task enters an unmapped area, and still asks before writing.
With no argument, update runs the full review.

**Why.** A catalog grows by the tasks that touch it, not by up-front effort; exhaustive
early mapping rots together. agent-kit's `memory <area>` and `rules <area>` did exactly
this, and folding them into `update` keeps the command count at two.

**Rejected.** Separate `memory` and `rules` commands (D20).

## D12. No commits unless asked

*2026-10-25, v0.1.0*

**Decision.** Neither skill commits. Repo changes are staged by name, and committing
follows the project's `rules/commit.md`.

**Why.** The commit policy is the project's, written by the rules pass. The plugin
should not pre-empt it.

**Rejected.** Committing the scaffold automatically.

## D13. Claude Code only

*2026-10-25, v0.1.0*

**Decision.** No manifests for, and no support of, other agent CLIs (Codex, Cursor).

**Why.** The vault boundary depends on Claude Code's permission rules, `CLAUDE.local.md`,
plugin hooks and skills. Other CLIs would get a weaker boundary that nobody tests.
`.agents/` and `AGENTS.md` stay tool-neutral, so other CLIs can still read the harness.

**Rejected.** Shipping Codex or Cursor manifests.

## D14. Not the spec's Obsidian vault path

*2026-10-25, v0.1.0*

**Decision.** The vault is `~/Cognisphere/<project>/`, not the spec's
`~/Obsidian/Vaults/Cognisphere/Projects/<p>`.

**Why.** The deeper path assumes an existing Obsidian vault layout that many users don't
have. Obsidian can open any folder as a vault, so `~/Cognisphere/<project>/` loses
nothing. `update` reports a configuration still pointing at the old layout.

**Rejected.** `~/Obsidian/Vaults/Cognisphere/Projects/<p>`.

## D15. Only `Read` and `Edit` permission rules

*2026-10-25, v0.1.0*

**Decision.** `settings.local.json` uses only `Read(...)` and `Edit(...)` rules for the
vault. `update` reports existing `Write(...)` rules as inert and does not remove them.

**Why.** `Write(...)` rules never match: `Edit` rules cover the Write tool. A `Write`
rule would look like protection while providing none.

**Rejected.** `Write(...)` allow and deny rules.

## D16. Vault files are not translated

*2026-10-25, v0.1.0*

**Decision.** The vault and `AGENTS.local.md` are in English, whatever the project's
language (D6).

**Why.** One set of templates, hints and checks. Translation would multiply them and let
them drift apart.

**Rejected.** Translated vault files.

## D17. No pre-written `00 Home.md`

*2026-10-25, v0.1.0*

Superseded by D21.

**Decision.** Every note, Home included, is a skeleton with hints, filled from sources
(D2).

**Why.** A fixed Home either says nothing about the project or says things that are
false for it. Filling from sources is what makes the Quick facts trustworthy.

**Rejected.** A fixed, pre-written `00 Home.md`.

## D18. `update` never writes to the vault or the local configuration

*2026-10-25, v0.1.0*

**Decision.** `update` checks and reports only (D3, D4). It does not repoint the
configuration, re-seed notes, or refresh templates.

**Why.** Both are owned by people, not by the plugin. Silent repairs there would destroy
state, or override a deliberate choice.

**Rejected.** Repointing config, re-seeding notes, refreshing templates from `update`.

## D19. No Windows support

*2026-10-25, v0.1.0*

Superseded by D22.

**Decision.** Linux and macOS only. agent-kit's Windows-only steps (Developer Mode,
`core.symlinks`, `MSYS=winsymlinks`) are dropped, and `install.sh` refuses other systems.

**Why.** The settings use `~/` paths, and the harness relies on symlinks (`.claude`,
`CLAUDE.md`, `CLAUDE.local.md`). Supporting Windows would mean a second, untested path
for each.

**Rejected.** Windows support.

## D20. Only two commands: `install` and `update`

*2026-10-25, v0.1.0*

Superseded in part by D28: a third command, `read`.
Superseded in part by D31: `harness` and `vault`, which `install` runs.

**Decision.** agent-kit's seven skills (scaffold, memory, rules, update-all,
update-hooks, update-memory, update-rules) collapse into `/cognisphere:install` and
`/cognisphere:update [area]`. Their bodies live on as procedures in `procedures/`,
ported near-verbatim and read on demand.

**Why.** Users need two verbs: set it up, keep it right. The procedures keep agent-kit's
tuned wording and eval coverage without exposing seven entry points.

**Rejected.** Commands other than `install` and `update`.

## D21. The vault holds only what nothing else holds

*2026-10-25, v0.2.0*

Superseded in part by D27: a code defect waits in Findings until the issue exists.

**Decision.** `Agent/` keeps only what git, the repo and the issue tracker do not: open
threads (harness work, open questions, decisions waiting on the maintainer), events git
doesn't record, the session log and scratch work. The seed is `00 Home.md`,
`State/{Open Threads, History}`, `Workflow/{Session Protocol, Vault Guide}`, `Log/` and
`Scratch/`. `Current State`, the `Working Agreement`, the `Review Checklist` and all of
`Knowledge/` are gone, as are Home's Quick facts, the Session Protocol's Commands and Open
Threads' Code group. History records only events git doesn't; the Log's Changed bullet
names the commit sha and lists files only for changes outside git. A code defect goes to
an issue, linked from the area's memory note; lasting knowledge about the code goes to
the memory note. The working style lives only in `AGENTS.local.md` (D7's second copy is
gone). The templates are complete as seeded, so `status: skeleton` and the deferred fill
are gone: install writes only its run's open questions to Open Threads and Session 1 of
the Log. `update` reports the v0.1.0 notes in an existing vault, with what to move out
before deleting them.

**Why.** Testing v0.1.0 on a real project showed every condensing note drifting within a
session. Current State recorded branch, HEAD and "uncommitted" and was wrong by the next
commit. History restated `git log`. The Knowledge notes, Index, Working Agreement, Review
Checklist and Quick facts copied memory notes, `AGENTS.md` and the rules, which are
already loaded every session: the agent read them twice, and each copy went stale the
first time its original changed. One bug sat in three places. A copy saves nothing when
the original is one command away or already in context, and the hints saying "condense,
don't copy" did not stop it.

**Rejected.** Keeping the notes with stricter hints, which were already there. Recording
check status with a date: it holds for one commit only, so anchor it to a sha or rerun
it. `update` deleting the old notes (D18).

## D22. Windows under Git Bash; install from inside Claude Code

*2026-10-25, v0.3.0*

The stop on a copied link is superseded by D23.

**Decision.** Windows is supported under Git Bash, after a one-time setup in the README
(Developer Mode, `core.symlinks true`, `MSYS=winsymlinks:nativestrict`). Each `ln -s` in
the procedures is checked with `[ -L ]`; a copy is removed and the run stops. Install and
update are the `/plugin` commands inside Claude Code, and `install.sh` is removed.

**Why.** Claude Code expands `~/` on Windows, Git Bash ships `perl` with `JSON::PP`, and
the guard tests pass there. The only real gap was symlinks, and Git Bash fails it
silently: `ln -s` copies, so the links drifted. Checking each link closes that. The
`/plugin` commands are the same on every system, so a shell script with its own platform
check added nothing.

**Rejected.** A Windows-specific install path. Keeping `install.sh` next to the
`/plugin` commands.

## D23. The mechanical steps are scripts

*2026-10-25, v0.4.0*

**Decision.** Everything deterministic in install moves out of the procedures into
`scripts/`: `scaffold.sh` (structure, links, `.gitignore` lines), `seed-vault.sh`,
`configure.sh` (the local files), `names.sh` (project and vault paths), `link.sh`,
`merge-json.pl` and `check-links.pl`. The procedures keep only the judgment: the
questions, the memory phases, the content of notes and rules. `link.sh` retries a copied
link with `MSYS=winsymlinks:nativestrict` and stops only when that fails too; the
permanent Windows setup becomes a reported follow-up. `names.sh` gives the vault path in
`C:/...` form under Git Bash. `merge-json.pl` keeps the file's key order. `vault.md`
§ Check becomes `vault-check.md`, so install and update each read only their part.

**Why.** On a real Windows install the agent copied the steps out of markdown and broke
them in transit: the Bash tool collapsed `\` in the inline link checker, so its regex
stopped compiling; `$HOME` gave an MSYS path the Read tool cannot open; every link
stopped the run although a native link worked without admin. Retyped code also costs
tokens to read and differs between runs. Scripts are read zero times and run the same
way every time.

**Rejected.** Escaping the inline snippets harder. A single `install.sh` (D22): the
steps are interleaved with questions, so one script per step.

## D24. Existing docs are adopted as pointer notes

*2026-10-25, v0.4.0*

**Decision.** A memory note with `kind: pointer` stands for a doc the repo already has:
`doc:` names it, `paths:` the code it covers. It is indexed, gets a read rule that names
the doc, and `memory-drift-guard` accepts the doc in place of the note. The memory
bootstrap adopts such docs first and maps only the gaps; the Vault Guide leaves a repo's
own plan or issue file in charge of its items.

**Why.** The bootstrap assumed nothing was written down. A repo with a per-class notes
file and a plan with status got a second copy of both, which drifts the way D21
describes.

**Rejected.** Moving the doc into `.agents/memory/`: it belongs to the repo's own
workflow, and other tools link to it where it is.

## D25. The session ends in the vault; the vault defers to the repo's own plan

*2026-10-26, v0.5.0*

**Decision.** `AGENTS.local.md` gains an end-of-session line: before the last reply, or
at the project's own hand-off step, append the session to the Log and update Open
Threads. Install names that hand-off step in the line when `AGENTS.md` has one; only the
local file changes. Home's reading order now includes Session Protocol. When the repo
keeps a plan with status and per-phase logs, that plan owns progress: install writes its
rows into the Vault Guide's table, and a Log session stays at session level. The install
report lists drift-guard coverage (the notes with `paths:`), and a pointer note is
proposed with `scripts/coupling.sh`'s figure: how many of the area's commits already
touch the doc. `merge-json.pl` parses with its own order-keeping reader, so no key
moves. `vault-check` also reports a missing end-of-session line, a plan doc the Vault
Guide doesn't name, the open Harness threads to re-check, and hooks in
`settings.local.json`.

**Why.** On a real v0.4.0 install the agent never wrote to the vault. The only line
loaded every session said to read Home at the start. Home's reading order skipped the
one note that says to log at the end, and the project's own end-of-unit ritual in
`AGENTS.md` had no vault step. The Vault Guide's table didn't know the project's plan,
so the plan and the Log both recorded progress. Install wrote no note with `paths:`, so
the drift guard and the read rules covered nothing until update. `merge-json.pl` sorted
keys by their first appearance in the text, so every `matcher` moved after the
top-level `hooks`.

**Rejected.** A Stop hook that nudges when today's Log is empty: Stop fires after every
reply, so it would force entries on sessions that changed nothing. Adding the vault step
to `AGENTS.md`: it is shared, and teammates have no vault.

## D26. `update` checks the user-level settings for guards that run twice

*2026-10-26, v0.6.0*

**Decision.** `vault-check` gains a step for `~/.claude/settings.json` (or
`$CLAUDE_CONFIG_DIR/settings.json`), run by `scripts/user-settings.pl`. It reports
agent-kit enabled, cognisphere enabled from more than one marketplace, and a hook that
runs a guard script, each with the fix for the user to apply. It reads only; `update`
never writes the user-level settings (`~/.claude/settings.json`). The project's own
`.claude` link to `.agents/` is a different folder: memory and rules are written there
as before.

**Why.** `review-settings` removes agent-kit's entries from the project's
`settings.json`, but the README installs plugins for the user, so that is where a
leftover agent-kit usually stays enabled. Nothing looked there, and every guard kept
running twice. External feedback on v0.5.0 found the double-running guards came from
the user level.

**Rejected.** Writing the fix into the user's settings: they apply to every project, not
just this one, so they belong to the user (D18). Checking it in `review-settings`: that
pass writes, and this one must not.

## D27. What the agent notices goes in Findings

*2026-10-26, v0.7.0*

**Decision.** The seed gains `State/Findings.md`: numbered items the agent noticed
outside its task (bug, risk, smell, test, improvement, idea), each with its file, the
commit it was seen at, the evidence, a suggestion and a status. `AGENTS.local.md` gains
two lines: append a finding when it is noticed, without fixing it; and, asked about
known issues or improvements, read Findings first, re-check each item against the code,
say which commit the answer stands at and offer a fresh scan. An item closes struck
through with its outcome: an issue, the plan, a memory note, a fix, or the maintainer's
rejection and its reason, which stays. The maintainer triages by telling the agent,
which stays the only writer of `Agent/`. A code defect waits there until the maintainer
opens its issue, instead of a Direction item asking for one. Install's Fill records the
defects the mapping passes came across; `vault-check` reports a section without the two
lines and the count of open findings.

**Why.** What the agent saw outside its task was said once in a reply and lost with the
scrollback, or sat in one Log session's Found bullet, spread across days. Answering
"known issues?" or "what would you improve?" took a scan of the repo, and a suggestion
the maintainer had turned down came back in the next session. Open Threads held only
questions blocking the work, and the defect rule left a bug with no home until someone
opened its issue. The capture line is in `AGENTS.local.md` because D25 showed that only
the always-loaded file gets the agent to write; writing on notice, not at the end, keeps
the detail compaction would drop.

**Rejected.** Todo and progress lists in the vault: the repo's plan and the Log own them
(D25), and a third copy drifts. One note per kind, or per item: one read must answer
every form of the question. Filing issues straight away: outward-facing, noisy, and each
one needs the maintainer's yes. A TODO file in the repo: unvetted opinions in a shared,
versioned file, and teammates have no vault. Reading Findings at every session start:
it is read when asked, and checked before adding to it.

## D28. `read` takes a note path as Obsidian copies it

*2026-10-26, v0.8.0*

**Decision.** A third command, `/cognisphere:read <note> [request]`, run only by the
maintainer (`disable-model-invocation`). It takes a note's path relative to the
Obsidian vault: `Human/draft.md`, or `<project>/Human/draft.md` when `~/Cognisphere`
itself is open, whose leading `<project>/` it drops. It joins the path to the vault
`AGENTS.local.md` names and reads the note, its embeds and the links its content depends
on, one level deep. It checks the note's claims about the code against the code, then
does the request that followed the path, or asks. It never writes the note. One command
covers `Human/` and `Agent/`: the copied path already names the folder. No script: the
agent already has the vault's absolute path, in the form the Read tool needs.

**Why.** Reading a note in Obsidian and handing it to the agent took retyping its
location. Obsidian's "Copy path" is relative to the Obsidian vault, while `@` resolves
against the repo, so a pasted path matched nothing.

**Rejected.** Two commands, `read-human-docs` and `read-agent-docs`: they differ only in
the folder, which the pasted path already holds. A resolver script that also took
wikilinks, `obsidian://` URIs and bare names: four times the code for inputs nobody
pastes, and a join of two paths is not the mechanical step D23 moves out of the
procedures. Letting the model invoke it: it acts on a pasted path, and its description
would sit in every session's context.

## D29. Rejected: a Git-user level in the vault path

*2026-10-26, v0.8.0*

**Decision.** Rejected decision: the vault stays at `~/Cognisphere/<project>/` (D1). It
does not move to `~/Cognisphere/<git-user>/<project>/`, and nothing in the plugin
changes.

**Why.** `~` is already per person: the vault lives in the OS account's home, so two
people on one machine never share one. The risk a namespace would address, two repos
with the same basename, is not solved by it: both are committed to by the same user and
land in the same folder, while D1's clash prompt already catches them. `user.name` is
not a stable key either: it can be unset, differ per repo (`includeIf`), change over
time, or hold spaces and accents, and any change points the agent at a new, empty vault,
orphans the old one and leaves `settings.local.json` granting the old path. Adopting it
would touch `names.sh`, the permission rules, install, update, tests and docs, and need
a migration for existing vaults, for no case anyone hit.

**Rejected.** `~/Cognisphere/<git-user>/<project>/`, keyed on `user.name` or
`user.email`. `~/Cognisphere/<owner>/<repo>/` taken from `origin`: it tells apart repos
with the same name, but breaks for repos with no remote, for forks, and when a repo is
renamed or transferred, and the clash prompt covers that case already.

## D30. Install can leave the repo layer untouched

*2026-10-26, v0.9.0*

Superseded in part by D31: the untouched setup moves to `/cognisphere:vault`, which
detects the mode instead of asking, and `/cognisphere:harness` adds the repo layer later.

**Decision.** Install's round of questions opens with one more: set up the repo layer,
or leave it untouched. It proposes **untouched** when git already tracks another
harness (`.agents/`, `AGENTS.md`, `CLAUDE.md` or `.claude/`, with no `rules/memory.md`
naming `/cognisphere:update`) or a previous run chose it. Untouched skips scaffold,
memory and rules, and runs `configure.sh --untouched`:

- `settings.local.json` goes where Claude Code reads it, `.claude/`, followed through
  the link when `.claude` is one;
- each local file git does not already ignore gets an anchored line in
  `.git/info/exclude`, never in `.gitignore`;
- `AGENTS.local.md` gains `## Repo layer`, the mode's only record;
- if git tracks one of the three files, the script exits 4 and writes nothing.

`update` reads `## Repo layer` and then runs only the vault, configuration and
user-settings checks. Its area mode stops, because mapping writes `.agents/`. Install
compares `git status --porcelain` before and after the run and reports any new line as a
defect.

**Why.** The vault is the part one person benefits from alone. The repo layer is shared,
so in a company repo that already has its own harness, or in someone else's repo,
adding it isn't one person's call. Before this, install created whatever the existing
harness lacked: `.gitignore` lines, settings entries, the anti-drift rule. A user who
wanted only the vault had to revert those edits by hand after every install and
update. `.git/info/exclude` ignores the local files without touching anything git
tracks. Writing the mode into `AGENTS.local.md` keeps it in the file that loads into
every session, so the agent knows it too, with no new config file.

**Rejected.** A separate `/cognisphere:stealth-install` command: `update` still needs to
know the mode, so it would add a command without removing a branch. A flag in
`settings.local.json`: Claude Code's schema has no place for it, and the agent doesn't
read that file. Keeping `.agents/settings.local.json` in untouched mode: with no
`.claude -> .agents` link, Claude Code never reads it, and the `Human/` deny rule would
silently not apply.

## D31. Three setup commands: `install` is `harness` plus `vault`

*2026-10-26, v0.10.0*

**Decision.** Install's two halves become commands of their own.
`/cognisphere:harness` sets up the versioned repo layer (scaffold, memory, rules) and
writes nothing under `~/Cognisphere/` and no local file. `/cognisphere:vault` sets up
the vault and the three local files (seed, configure, fill) and writes nothing git
tracks. `/cognisphere:install` runs `harness` then `vault`, asking both rounds of
questions as one, and always does both: leaving a half out means running the other
command, never a hidden answer.

No `## Agent workspace` in `AGENTS.local.md`, or no such file, means "no vault":
`update` skips the vault and local-configuration checks with one line pointing at
`/cognisphere:vault`, still checks the user-level settings, and reports only a vault the
configuration lost (the folder exists, or a settings file names it). `read` stops the
same way.

D30's question leaves install. `names.sh` prints `repo_layer`: `cognisphere` when
`.agents/rules/memory.md` names `/cognisphere:update` and `AGENTS.local.md` has no
`## Repo layer`, otherwise `untouched`. `configure.sh` reads it in place of the
`--untouched` flag: untouched still puts the settings in `.claude/`, ignores the files
through `.git/info/exclude` and writes `## Repo layer`, which keeps the agent's two lines
for such a repo and keeps `update` off the repo layer. Install, finding another tool's
harness, proposes `/cognisphere:vault` and stops on that choice.

`harness` run after `vault` moves the local configuration over: the vault's
`.claude/settings.local.json` is merged into `.agents/settings.local.json` before
`.claude` becomes the link, and `scripts/repo-layer.sh` removes `## Repo layer` and each
`.git/info/exclude` line the new `.gitignore` entries make redundant. It asks first and
never touches the vault.

**Why.** The vault is personal and the repo layer is shared, so each is wanted alone: a
teammate cloning a repo that has the harness wants only a vault, and install's whole
round of questions was the only way there, while `update` reported the missing vault as
broken. Someone who wants only the harness had no way to say so. A vault-only repo had
no way to the harness: install stopped at `## Repo layer` and asked for a hand edit, and
`scaffold.sh` then hit the real `.claude/`. An opt-out answered inside install is
behavior nobody sees afterwards; a command named after what it sets up says it. With the
absence of the local files meaning "no vault", each person decides for themselves and
nothing records the choice. D30 rejected a separate command because `update` would still
need the mode; `## Repo layer` already records it, and the mode follows from the repo
itself.

**Rejected.** A "set up the vault too?" question in install: an implicit opt-out, and two
ways to a harness-only setup. Only `vault` as a separate command, with install handling
the move to the harness: smaller, but the two opt-outs would work differently.
Recording the opt-out in `AGENTS.local.md`: the file's absence already says it, and
writing it would leave a personal file in every opted-out clone. Keeping `--untouched`
as an override: the detection covers every case it was passed for, and a flag that
disagrees with `## Repo layer` would split the record.
