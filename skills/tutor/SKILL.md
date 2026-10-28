---
name: tutor
description: Switches this project's working style to tutor - the maintainer writes the code to learn; the agent explains, reviews and sketches diffs, and doesn't edit repo files unless asked. Rewrites § Working style in the project's gitignored AGENTS.local.md, so it holds for this project only, from this session on.
disable-model-invocation: true
---

# tutor

Runs only when the maintainer types it. The procedure is
`${CLAUDE_PLUGIN_ROOT}/procedures/style.md`; read it and follow it with style `tutor`.
To switch to another style, run `/cognisphere:auto` or `/cognisphere:copilot`.
