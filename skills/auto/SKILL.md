---
name: auto
description: Switches this project's working style to auto - the agent takes a goal, plans the subtasks, implements and verifies on its own, and stops to ask only when the goal is unclear or before a destructive or outward-facing action. Rewrites § Working style in the project's gitignored AGENTS.local.md, so it holds for this project only, from this session on.
disable-model-invocation: true
---

# auto

Runs only when the maintainer types it. The procedure is
`${CLAUDE_PLUGIN_ROOT}/procedures/style.md`; read it and follow it with style `auto`.
To switch to another style, run `/cognisphere:copilot` or `/cognisphere:tutor`.
