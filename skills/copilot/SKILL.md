---
name: copilot
description: Switches this project's working style to copilot - the maintainer drives; the agent answers, reviews and suggests when asked, and writes code only for a task handed over, then hands the wheel back. Rewrites § Working style in the project's gitignored AGENTS.local.md, so it holds for this project only, from this session on.
disable-model-invocation: true
---

# copilot

Runs only when the maintainer types it. The procedure is
`${CLAUDE_PLUGIN_ROOT}/procedures/style.md`; read it and follow it with style `copilot`.
To switch to another style, run `/cognisphere:auto` or `/cognisphere:tutor`.
