---
tags: [{{project}}, agent, workflow, meta]
updated: {{date}}
---
# Vault Guide: structure and how the agent builds it

Back: [[00 Home]] · [[Session Protocol]] · [[Working Agreement]]

This note is the spec for the agent's Obsidian workspace. A future agent session with an empty `Agent/` folder should be able to rebuild the vault from this note alone, and keep it healthy afterwards.

---

## 1. Purpose and ownership

- **`Agent/`** is the agent's scratchpad and long-term memory for {{project}}. The agent is the **only writer**.
- **`../Human/`** holds the maintainer's notes. The agent **reads** them and **never writes** there.
- **The repo is not touched** from this workflow. The agent works in the role the [[Working Agreement]] sets: it edits repo files only as that role allows, and maintaining this vault never edits the repo.
- **Authority order** when sources disagree:
  **code** > `AGENTS.md` > `.agents/memory/` > this vault > `docs/`.
  The vault is a condensed, browsable mirror plus the agent's own state and log. If the vault and the repo disagree, the repo wins and the vault gets fixed.

Why a vault when the repo already has `.agents/memory/`? The repo graph is shared, versioned and loaded into every session, so it must stay lean and factual. The vault holds what doesn't belong in git: session history, open questions, the agent's working agreement with the maintainer, scratch work, and a human-readable overview.

---

## 2. Layout

```
Agent/
├── 00 Home.md                 entry point: ground rules, map, quick facts
├── State/
│   ├── Current State.md       snapshot: repo, product, harness, right now
│   ├── History.md             milestones, newest first, with PR numbers
│   └── Open Threads.md        numbered unresolved items: bugs, debts, decisions
├── Workflow/
│   ├── Session Protocol.md    start / during / end routine + commands
│   ├── Working Agreement.md   roles, git, tests, guardrails, harness
│   ├── Review Checklist.md    checkbox list for reviewing the maintainer's diffs
│   └── Vault Guide.md         this note
├── Knowledge/
│   ├── Index.md               domain map + the non-negotiables
│   ├── <Domain or Area>.md    one per domain, or per major area in a single-domain repo
│   └── Docs Drift.md          table of where written docs are wrong
├── Log/
│   └── YYYY-MM-DD.md          one note per day, one "## Session N" block per session
└── Scratch/
    ├── README.md              rules for the folder
    └── YYYY-MM-DD topic.md    throwaway work
```

The top level stays at **one note plus five folders**. Don't add new top-level folders without the maintainer's agreement.

---

## 3. What goes where

### `00 Home.md`
- One paragraph on what {{project}} is, plus the repo path and default branch.
- The **reading order** for a new session: Home → [[Current State]] → [[Open Threads]] → the latest Log.
- **Ground rules:** the role from the [[Working Agreement]], write only in `Agent/`, the authority order.
- A **map** table: one row per folder, linking its notes.
- **Quick facts:** six to eight bullets an agent must never get wrong — the facts whose mistake breaks something on the first edit (runtime, units, auth model, what is real vs mock…), each taken from `AGENTS.md` or a memory note.
- Keep it under one screen. It's an index, not content.

### `State/`: "where are we?"
| Note | Contains | Updated when |
|---|---|---|
| [[Current State]] | branch, HEAD, test/build/lint status (marked *verified* or *not run*), what's real vs mock, infra, harness summary | any session that changes facts |
| [[History]] | dated milestones grouped by month, newest first, PR numbers in brackets | a PR merges or a notable event happens |
| [[Open Threads]] | **numbered** items grouped as Harness / Code / Direction. Each has the evidence and the fix options | something is found or resolved. Close an item by ~~striking it through~~ with the date and PR. Never delete or renumber |

### `Workflow/`: "how do we work?"
- [[Session Protocol]]: a checklist for start, during and end, plus the commands the agent actually uses.
- [[Working Agreement]]: roles (tutor vs author), git rules, tests, permission denies and hooks, the subagents and slash commands, the memory-graph rules.
- [[Review Checklist]]: checkboxes grouped as landmines → interfaces → one group per major area with rules of its own → tests → hygiene → memory drift. It's derived from `.agents/rules/`, the memory notes and the `cognisphere:reviewer` agent prompt.
- Vault Guide: this spec.

### `Knowledge/`: "what's true about the system?"
- One note per domain or major area, plus `Index.md` and `Docs Drift.md`.
- Each note has `source:` frontmatter pointing to the repo files it condenses.
- **Content rule (anti-drift):** write the *why*, the gotchas and the latent bugs. **Point to the code for the *what*.** Don't copy tables of numbers, rates or file inventories: inventory is what rots first.
- Each note ends with a `Related:` line of wikilinks.

### `Log/`: "what happened?"
- `Log/YYYY-MM-DD.md`, with one `## Session N` block per session, using these bullets:
  **Asked**, **Found**, **Did**, **Changed**, **Not verified**, **Next**.
- Append only. Don't rewrite past sessions.

### `Scratch/`: "thinking space"
- Diff sketches, maths checks, half-ideas. `YYYY-MM-DD topic.md`.
- Nothing here is authoritative. Promote what's worth keeping, then delete the file.

---

## 4. Bootstrap: creating the vault from scratch

Do this when `Agent/` is empty, `00 Home.md` is missing, or notes are still `status: skeleton`.

1. **Confirm the scope with the maintainer.** Creating the vault is a request, not a reflex. If `00 Home.md` is missing or still a skeleton, say so and ask before building or filling anything.
2. **Re-seed the skeleton** if notes are missing: `/cognisphere:install` creates only what is missing and never touches an existing note. Without the plugin, create them by hand from the layout in § 2 and the conventions in § 6.
3. **Read the sources** (read-only):
   - `AGENTS.md` (authoritative quick reference) and `AGENTS.local.md` (the working style and this workspace)
   - `.agents/memory/MEMORY.md` and every note it links
   - `.agents/rules/*.md`, `.agents/settings.json` and `.agents/settings.local.json`
   - the project's own `.agents/agents/`, `.agents/skills/` and `.agents/hooks/`, if any, and the cognisphere agents (`cognisphere:explorer`, `planner`, `implementer`, `test-runner`, `reviewer`)
   - `git log` (both merge commits and plain commits) for [[History]]
   - `ls ../Human/`. List the notes there but don't summarise them unless asked.
4. **Check what you can.** At minimum run `git status` and `git log -5`. Mark anything you didn't run (tests, build, lint) as **not verified** in [[Current State]].
5. **Fill the notes in this order**, so links resolve as you go:
   1. `00 Home.md`
   2. `State/`: Current State → History → Open Threads
   3. `Workflow/`: Session Protocol → Working Agreement → Review Checklist → Vault Guide
   4. `Knowledge/`: Index first, then one note per domain or major area, then Docs Drift
   5. `Scratch/README.md`
   6. `Log/<today>.md`, recording the bootstrap itself

   Each section's hint comment names its source. What no source says stays *unknown* or *not verified*; never invent to fill a section. Remove `status: skeleton` from a note once it is filled.
6. **Check the links.** `grep -rn '\[\[' Agent/` should show no links to missing notes (e.g. `[[State]]` and `[[Workflow]]` after a folder split).
7. **Report to the maintainer** with the tree, the sources used, what wasn't verified, and any problems found along the way.

---

## 5. Maintenance

- **Every session**, follow [[Session Protocol]]: read Home → State → Log at the start, and at the end append to the Log and update State.
- **Promotion path:** Scratch → Log (what happened) → Knowledge (durable truth) or Open Threads (unresolved).
- **Repo drift:** if the vault turns out to contradict the repo's `.agents/memory/`, fix the vault and **tell the maintainer** about the repo note. Don't edit the repo from this workflow.
- **Restructuring** (say, a note split into a folder): create the new notes first, delete the old note, rewrite every link, log the change. `Agent/` is yours to adapt; the plugin seeded it once and never maintains it.
- **Don't let notes bloat.** If a Knowledge note grows past about a screen and a half, it's probably copying inventory. Cut it back to pointers.

---

## 6. Conventions

- **Frontmatter** on every note: `tags: [{{project}}, agent|knowledge, <area>]` and `updated: YYYY-MM-DD`. Log notes use `date:`. Knowledge notes add `source:`.
- **`status: skeleton`** in the frontmatter marks a note seeded from a template and not filled yet. Filling the note removes the line. Log notes and `Scratch/README.md` never carry it.
- **Hint comments:** each section of a seeded note carries a one-line `<!-- … -->` naming where its facts come from. They are invisible in Obsidian's reading view. Keep them after filling, as guidance for later sessions.
- **Navigation line** under the H1: `Back: [[00 Home]] · [[sibling]] …` (Knowledge uses `Up: [[Index]]`).
- **Wikilinks** by bare note name (`[[Open Threads]]`), with an alias when helpful (`[[Knowledge/Index|Knowledge]]`). Inside a table, escape the alias pipe (`[[Knowledge/Index\|Index]]`).
- **Names:** Title Case with spaces for notes, ISO dates for Log and Scratch, `00 ` prefix only for Home.
- **Dates:** absolute, never "yesterday" or "last week".
- **Language:** English for the vault. Keep domain terms as the code's language names them.
- **Markers:** ⚠️ for a gotcha, ⚡ for core business logic, ~~strikethrough~~ for a closed thread.
- **People:** "the maintainer". No names, no assumed pronouns.

---

## 7. Pitfalls

- **Don't copy secrets.** Credentials can sit in `../Human/` or in local files the agent is denied (`.env`). Never copy credentials into the vault. A value already public in the repo (a seed login in a test) is the only exception.
- **Don't summarise `Human/` without being asked.** Those are the maintainer's notes, and summarising them invites drift between two copies.
- **Don't invent verification.** If tests weren't run this session, say "not verified" rather than repeating old numbers as current.
- **Don't treat the vault as the source of truth.** It loses to the code every time.
