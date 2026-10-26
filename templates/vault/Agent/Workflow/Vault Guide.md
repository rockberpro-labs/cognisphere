---
tags: [{{project}}, agent, workflow, meta]
updated: {{date}}
---
# Vault Guide: what the vault holds and how it is kept

Back: [[00 Home]] · [[Session Protocol]]

This note is the vault's own rulebook. `/cognisphere:vault` (or `/cognisphere:install`) seeded the notes; `/cognisphere:vault` re-seeds a missing one and never touches an existing one. From here on the agent keeps `Agent/` healthy by these rules.

---

## 1. Purpose and ownership

- **`Agent/`** is the agent's workspace for {{project}}. The agent is the **only writer**.
- **`../Human/`** holds the maintainer's notes. The agent **reads** them and **never writes** there.
- **Maintaining this vault never edits the repo.** The agent edits repo files only as `AGENTS.local.md` § Working style allows.
- **Authority order** when sources disagree:
  **code** > `AGENTS.md` > `.agents/memory/` > this vault > `docs/`.
  If the vault and the repo disagree, the repo wins and the vault gets fixed.

**The vault holds only what nothing else holds.** `AGENTS.md`, `AGENTS.local.md` and the `.agents/` rules load into every session, and git answers in one command. A copy of any of them here is read twice and goes stale the first time the original changes. Read these at the source instead:

| Fact | Where it lives |
|---|---|
| Branch, HEAD, working tree, what is committed | `git status`, `git log` |
| Milestones, merges, PR numbers | `git log`, the forge |
| Test, build, lint status | run it now; the commands are in `AGENTS.md` |
| Commands, conventions, non-negotiables | `AGENTS.md`, `.agents/rules/` |
| The agent's role | `AGENTS.local.md` § Working style |
| How an area works, its gotchas | its `.agents/memory/` note |
| A defect in the code | an issue, linked from the area's memory note; [[Findings]] until the maintainer opens it |
| Planned work and its status | the repo's own plan, TODO or issue file, when it has one |
| What `.agents/` contains | `ls .agents/` |
| What a review checks | the `cognisphere:reviewer` agent |

What is left is the agent's own: open threads, what it noticed along the way, how the maintainer wants it to work, events git doesn't record, the session log and scratch work.

`Scratch/` is the exception to this rule: it is the agent's workbench for its output, written freely, one folder per day. Only today's folder is current; older ones are history.

---

## 2. What goes where

### `00 Home.md`
- The repo path, the **reading order** (Home → [[Session Protocol]] → [[Preferences]] → [[Open Threads]] → the latest Log, then git), the **ground rules** and a **map** of the folders.
- No facts about the project: they live in `AGENTS.md`. It's an index and stays under one screen.

### `State/`: "what is open?"
| Note | Contains | Updated when |
|---|---|---|
| [[Open Threads]] | **numbered** items grouped as Harness / Direction, each with the evidence and the options | something is found or resolved. Close an item by ~~striking it through~~ with the date and the closing commit or PR. Never delete or renumber |
| [[Findings]] | **numbered** items the agent noticed outside its task: a bug, risk, smell, missing test, improvement or idea, each with its file, the commit it was seen at, the evidence and a suggestion | the agent notices one (right away, not at the end), or the maintainer decides on one. Close it by striking it through with the outcome: an issue, the plan, a memory note, a fix, or a rejection and its reason. Never delete or renumber |
| [[History]] | dated events git doesn't record (a deploy, an incident, a decision made outside a commit), grouped by month, newest first | such an event happens |
| [[Preferences]] | how the maintainer wants the agent to work (corrections and approaches they confirmed, each with its reason) and what the agent should know about them to work well (expertise, what they own); what Claude Code's auto-memory would otherwise keep | the maintainer corrects the agent or confirms an approach in a way meant to hold beyond the task. Rewrite an item when it changes; the Log keeps the moment it was said |

[[Preferences]] is current by definition: the Log records a correction when it happens, Preferences holds the standing rule. The role set at install stays in `AGENTS.local.md` § Working style; a preference the maintainer wants enforced in every session goes there too, and only the maintainer edits that file.

When the repo keeps its own plan, TODO or issue file, that file owns its items: [[Open Threads]] and [[Findings]] link it and hold only what it doesn't.

**Open Threads or Findings?** A question or decision the maintainer must answer for the work to go on is a thread. Something the agent saw and the maintainer may act on, or not, is a finding.

A code defect isn't a thread. Its home is an issue, and the area's memory note links to it. Until the maintainer opens the issue, it is a [[Findings]] item of kind `bug`; it then gets "→ issue #N". The agent's working notes on a defect (a repro script, a half-done diagnosis) go in `Scratch/`.

[[Findings]] is a record of what the agent saw, not an audit: it covers only the areas the agent worked in, and each item holds at the commit it was seen at. Asked for known issues or suggestions, the agent reads it first, re-checks each open item against the code, says which commit the answer stands at, and offers a fresh scan.

Rejected findings stay, struck through with the maintainer's reason, so the same suggestion doesn't come back. The maintainer triages by telling the agent; the agent records the outcome, since it is the only writer of `Agent/`.

### `Workflow/`: "how do we work?"
- [[Session Protocol]]: the start, during and end checklist.
- Vault Guide: this note.

### `Log/`: "what happened?"
- `Log/YYYY-MM-DD.md`, with one `## Session N` block per session, using these bullets:
  **Asked**, **Found**, **Did**, **Changed**, **Not verified**, **Next**.
- **Changed** names the commit sha for repo changes, or says "uncommitted" when there is none yet; it lists files only for changes git doesn't see (the vault, the local configuration).
- Append only. Don't rewrite past sessions.
- When the repo keeps its own progress log (a plan with status, next steps and per-phase logs), that log owns what was built and what comes next. A session here stays at session level: Asked, Not verified, harness threads. **Did** and **Next** point to the plan's entry instead of restating it.

### `Scratch/`: "what is the work producing?"
- What the work produces (plans, scripts, drafts, diff sketches, repro scripts, intermediate output) and notes on it (files touched, dead ends ruled out). Output, not thinking aloud: what the next session would need, not the reasoning that got there. `YYYY-MM-DD/topic.md`, one folder per day.
- Written freely: a copy of something held elsewhere is fine here. It takes what would otherwise go to Claude Code's session scratchpad, so the work travels with the vault; a plan-mode plan is copied here as `plan <name>.md`. Throwaway material (a test repo, a download, build output) stays out: it goes in a `mktemp -d` folder.
- Written at set moments: before the first edit of a task, and before a long investigation. The `scratch-first` hook refuses repo edits until a note exists this session, and again once 3 repo files changed since the last write; the Stop hook asks again when a session touched 3 or more repo files and nothing here changed.
- Nothing here is authoritative. At session end, promote what's worth keeping; the day folder stays as history. Read an older day folder only when the task needs it, never as the current state.

The top level stays at **one note plus four folders**. Don't add new top-level folders without the maintainer's agreement.

---

## 3. Maintenance

- **Every session**, follow [[Session Protocol]].
- **Promotion path:** Scratch → Log (what happened) → Open Threads (unresolved), Findings (noticed, for the maintainer to triage), Preferences (how the maintainer wants the agent to work, from now on), or the area's `.agents/memory/` note (lasting truth about the code: fix it if the role allows, otherwise tell the maintainer).
- **Repo drift:** if the vault contradicts the repo, fix the vault and **tell the maintainer** about the repo note. Don't edit the repo from this workflow.
- **Copy creep:** a note that starts restating git, `AGENTS.md`, a rule or a memory note gets cut back to a pointer, or deleted.
- **Restructuring** (say, a note split into a folder): create the new notes first, delete the old note, rewrite every link, log the change. `Agent/` is yours to adapt; the plugin never maintains it.
- **Missing notes:** `/cognisphere:vault` re-seeds them from its templates and leaves the rest alone.

---

## 4. Conventions

- **Frontmatter** on every note: `tags: [{{project}}, agent, <area>]` and `updated: YYYY-MM-DD`. Log notes use `date:`.
- **Hint comments:** a section may carry one short `<!-- … -->` saying what belongs there. They are invisible in Obsidian's reading view. Keep them; never repeat the same block across notes.
- **Navigation line** under the H1: `Back: [[00 Home]] · [[sibling]] …`.
- **Wikilinks** by bare note name (`[[Open Threads]]`), with an alias when helpful (`[[Scratch/README|Scratch]]`). Inside a table, escape the alias pipe (`[[Scratch/README\|Scratch]]`).
- **Names:** Title Case with spaces for notes, ISO dates for Log notes and Scratch day folders, `00 ` prefix only for Home.
- **Dates:** absolute, never "yesterday" or "last week".
- **Anchors:** a status that depends on the code (tests pass, a bug reproduces) names the commit: "at `<sha>`". A date alone means nothing after the next commit.
- **Language:** English for the vault. Keep domain terms as the code's language names them.
- **People:** "the maintainer". No names, no assumed pronouns.

---

## 5. Pitfalls

- **Don't copy the repo.** See § 1: a copy saves nothing and drifts.
- **Don't copy secrets.** Credentials can sit in `../Human/` or in local files the agent is denied (`.env`). Never copy credentials into the vault. A value already public in the repo (a seed login in a test) is the only exception.
- **Don't fill Scratch with throwaway material.** A test repo, a download or build output in the vault is backed up, synced and indexed by Obsidian for nothing. It goes in a `mktemp -d` folder; the script that made it can stay in Scratch.- **Don't summarise `Human/` without being asked.** Those are the maintainer's notes, and summarising them invites drift between two copies.
- **Don't invent verification.** If a check wasn't run this session, say "not verified" rather than repeating an old result as current.
- **Don't treat the vault as the source of truth.** It loses to the code every time.
