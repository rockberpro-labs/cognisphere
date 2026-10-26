---
tags: [{{project}}, agent, scratch]
updated: {{date}}
---
# Scratch

Back: [[00 Home]] · [[Session Protocol]]

The agent's working memory: plans, files touched, dead ends ruled out, diff sketches, maths checks, half-ideas, repro scripts.

- Write freely. The "only what nothing else holds" rule ([[Vault Guide]] § 1) doesn't apply here: a working copy is fine while the work lasts.
- Before the first edit of a multi-step task, start `YYYY-MM-DD topic.md` with the plan, the files to touch and the open questions; keep it current (the `scratch-first` hook refuses repo edits until it exists). Before a long investigation, note what you're looking for and what you've ruled out.
- Nothing here is authoritative.
- At session end, promote what is worth keeping (to `Log/`, [[Open Threads]], [[Findings]] or the area's `.agents/memory/` note, per [[Vault Guide]] § 3), then delete the file. The `session-start` hook lists any file left behind.
