# Human

This folder is your notes. Agents read it and cannot write here (denied in `.agents/settings.local.json`); they don't summarise it unless you ask.

- `../Agent/` is the agent's workspace: read it anytime, and ask the agent for changes, since it is the only writer.
- Ask the agent to graduate stable ideas into the repo (`AGENTS.md`, `.agents/memory/`, `docs/`).
- This folder is not backed up; see `../../README.md`.
- To hand a note to the agent, copy its path in Obsidian and run `/cognisphere:read <path> [what to do]` in the project's Claude Code session.
