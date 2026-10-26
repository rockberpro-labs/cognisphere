---
tags: [{{project}}, agent, workflow]
updated: {{date}}
---
# Session Protocol

Back: [[00 Home]] · [[Vault Guide]]

## Start
- [ ] Read [[00 Home]], this note, [[Preferences]], [[Open Threads]] and the latest `Log/` note (the `session-start` hook loads all but this note). Move any loose `Scratch/` file it lists into its day folder; today's folder, if it has notes, is the work in flight.
- [ ] Run `git status` and `git log -5`; note what changed since the last session.
- [ ] Re-check the open Harness threads: one may be resolved already (a restart, a trust prompt). Close it with the evidence.
- [ ] Before touching an area, read its `.agents/memory/` note.

## During
- [ ] `Scratch/` is your workbench for what the work produces: write freely, nothing there is authoritative. Before the first edit of a multi-step task, write the plan, the files to touch and the open questions in `Scratch/<today>/<topic>.md`; before a long investigation, what you're looking for and what you've ruled out. Keep it current. Scripts, drafts and intermediate output go there too, not in Claude Code's scratchpad. Output, not thinking aloud.
- [ ] The maintainer corrects you or decides something → record it in today's Log (or [[Open Threads]], if it leaves a question open) before continuing. When it is meant to hold beyond this task (how to work, what to avoid, an approach they confirmed), also add or rewrite it in [[Preferences]], with the reason. That's where Claude Code's auto-memory would have kept it.
- [ ] Something unresolved → a new numbered item in [[Open Threads]].
- [ ] Noticed something outside the task (a code defect, a risk, an improvement) → a new item in [[Findings]] now, not at the end. Don't fix it unasked.
- [ ] The maintainer decided on a finding (an issue opened, planned, rejected) → strike it through with that outcome.
- [ ] Learned something lasting about the code → it belongs in the area's `.agents/memory/` note: fix it if the role allows, otherwise tell the maintainer. Never park it in the vault.
- [ ] The vault contradicts the repo → the repo wins: fix the vault, tell the maintainer about the repo note.

## End
Before the session's last reply, or at the project's own hand-off step when `AGENTS.md` has one.
- [ ] The repo keeps its own plan or progress log → update it first, as `AGENTS.md` says. The Log below points to it and doesn't restate it ([[Vault Guide]] § 2).
- [ ] Append `## Session N` to `Log/<today>.md`: Asked, Found, Did, Changed, Not verified, Next.
- [ ] Add or close [[Open Threads]]; check that what this session noticed is in [[Findings]]; add to [[History]] only what git doesn't record.
- [ ] Promote from today's `Scratch/` folder what matters. The folder stays, as history.
