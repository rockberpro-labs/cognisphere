# Maintainer's local instructions (gitignored)

## Working style

{{working_style}}

## Agent workspace

- The vault for this project is `{{vault}}` (outside the repo, not in git).
- At the start of every session, including one opened by a slash command, read `{{vault}}/Agent/00 Home.md` and follow its reading order.
- Before the last reply of a session that changed or decided anything (or at the project's own hand-off step in `AGENTS.md`, when it has one), append `## Session N` to `{{vault}}/Agent/Log/<today>.md` and update `State/Open Threads.md`, as `Workflow/Session Protocol.md` § End says.
- When you notice something outside the task (a bug, a risk, a smell, a missing test, an improvement, an idea), append it to `{{vault}}/Agent/State/Findings.md` right away, as its hint comment says, after checking that it isn't there already. Don't fix it unasked, and don't drift from the task.
- Asked about known issues, problems, suggestions or what you would improve → read `State/Findings.md` first. Re-check each open item against the code (`git log <sha>..HEAD -- <path>`) before you report it, say the answer is from the vault as of which commit, and offer a fresh scan: the vault only covers the areas you have worked in.
- `{{vault}}/Agent/` is the agent's workspace, and the agent is its only writer. It holds only what nothing else holds: open threads, findings, the session log, scratch. Never copy into it what git, `AGENTS.md`, `.agents/` or an issue already holds.
- `{{vault}}/Human/` is the maintainer's: read-only. Don't summarise it unless asked.
- `00 Home.md` missing → say so; `/cognisphere:install` re-seeds the missing notes and leaves the rest alone.

## Repo layer

- Left untouched at install: cognisphere writes nothing git tracks in this repo. The three local files are ignored through `.git/info/exclude`, not `.gitignore`.
- `/cognisphere:update` checks only the vault and this configuration. Don't add cognisphere's files to the repo (`.agents/` notes or rules, `AGENTS.md` sections, `.gitignore` lines) unless the maintainer asks.
- Where the vault guide points at `.agents/memory/` and this repo has no such note, the code and `AGENTS.md` are the source.
