# Maintainer's local instructions (gitignored)

## Working style

{{working_style}}

## Agent workspace

- The vault for this project is `{{vault}}` (outside the repo, not in git).
- At session start, read `{{vault}}/Agent/00 Home.md` and follow its reading order.
- `{{vault}}/Agent/` is the agent's workspace, and the agent is its only writer. It holds only what nothing else holds: open threads, the session log, scratch. Never copy into it what git, `AGENTS.md`, `.agents/` or an issue already holds.
- `{{vault}}/Human/` is the maintainer's: read-only. Don't summarise it unless asked.
- `00 Home.md` missing → say so; `/cognisphere:install` re-seeds the missing notes and leaves the rest alone.
