---
tags: [{{project}}, agent, scratch]
updated: {{date}}
---
# Scratch

Back: [[00 Home]] · [[Session Protocol]]

The agent's workbench: what its work produces while it works (plans, scripts, drafts, diff sketches, repro scripts, intermediate output) and the notes on that work (files touched, dead ends ruled out, what's still open).

- Output, not thinking aloud: write what the work produced and what the next session would need, not the reasoning that got there.
- Output worth keeping, not throwaway material: a test repo, a download, build output or a generated fixture goes in a `mktemp -d` folder outside the vault, so it doesn't fill the backups or Obsidian. Keep the script that made it, if it matters, here.
- One folder per day: `YYYY-MM-DD/topic.md`; a session started in a sub-project, `YYYY-MM-DD/<tag>/topic.md` ([[Vault Guide]] § 4). Today's folder is the work in flight; older folders are history, read only when a task needs them.
- Write freely. The "only what nothing else holds" rule ([[Vault Guide]] § 1) doesn't apply here: a working copy is fine.
- This is where the agent's output goes instead of Claude Code's session scratchpad, so it travels with the vault. A plan-mode plan is copied here as `plan <name>.md`. What auto-memory would keep about the maintainer goes in [[Preferences]], not here.
- Before the first edit of a multi-step task, start a note with the plan, the files to touch and the open questions; keep it current (the `scratch-first` hook reminds you after a repo edit while there is none, and again once 3 repo files changed since the last write; it never blocks). Before a long investigation, note what you're looking for and what you've ruled out.
- Nothing here is authoritative.
- At session end, promote what is worth keeping (to `Log/`, [[Open Threads]], [[Findings]] or the area's `.agents/memory/` note, per [[Vault Guide]] § 3). The day folder stays.
