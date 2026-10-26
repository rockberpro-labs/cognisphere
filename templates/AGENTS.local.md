# Maintainer's local instructions (gitignored)

## Working style

{{working_style}}

## Agent workspace

- The vault for this project is `{{vault}}` (outside the repo, not in git).
- At the start of every session, including one opened by a slash command, follow `{{vault}}/Agent/00 Home.md`'s reading order. The `session-start` hook loads Home, `State/Open Threads.md` and the latest Log note into context; when they aren't there, read them yourself.
- Before the last reply of a session that changed or decided anything (or at the project's own hand-off step in `AGENTS.md`, when it has one), append `## Session N` to `{{vault}}/Agent/Log/<today>.md` and update `State/Open Threads.md`, as `Workflow/Session Protocol.md` § End says.
- `{{vault}}/Agent/Scratch/` is your working memory: write to it freely while you work, without asking whether something else holds it. Before the first edit of a multi-step task, write `Scratch/<today> <topic>.md` with the plan, the files you'll touch and the open questions, and keep it updated as you go. The `scratch-first` hook refuses repo edits until such a note exists.
- Before a long investigation (several files or commands), write in that Scratch note what you're looking for and what you've ruled out, and add what you find.
- When the maintainer corrects you or decides something, record it in `Log/<today>.md` (or `State/Open Threads.md`, when it leaves a question open) before you continue.
- At the end of the session, promote from Scratch what matters (to the Log, Open Threads, Findings or the area's `.agents/memory/` note), then delete the rest.
- When you notice something outside the task (a bug, a risk, a smell, a missing test, an improvement, an idea), append it to `{{vault}}/Agent/State/Findings.md` right away, as its hint comment says, after checking that it isn't there already. Don't fix it unasked, and don't drift from the task.
- Asked about known issues, problems, suggestions or what you would improve → read `State/Findings.md` first. Re-check each open item against the code (`git log <sha>..HEAD -- <path>`) before you report it, say the answer is from the vault as of which commit, and offer a fresh scan: the vault only covers the areas you have worked in.
- `{{vault}}/Agent/` is the agent's workspace, and the agent is its only writer. Outside `Scratch/` it holds only what nothing else holds: open threads, findings, the session log. Never copy into those what git, `AGENTS.md`, `.agents/` or an issue already holds.
- `{{vault}}/Human/` is the maintainer's: read-only. Don't summarise it unless asked.
- `{{root}}/Shared/` holds the maintainer's notes for every project: read-only. Read a note there when the maintainer points at it or the task needs it; don't load the folder whole. Never read another project's folder under `{{root}}/Projects/`.
- `00 Home.md` missing → say so; `/cognisphere:vault` re-seeds the missing notes and leaves the rest alone.

## Repo layer

- Not cognisphere's to change (`/cognisphere:vault` set up only the vault): cognisphere writes nothing git tracks in this repo. The three local files are ignored through `.git/info/exclude`, not `.gitignore`.
- `/cognisphere:update` checks only the vault and this configuration. Don't add cognisphere's files to the repo (`.agents/` notes or rules, `AGENTS.md` sections, `.gitignore` lines) unless the maintainer asks.
- Where the vault guide points at `.agents/memory/` and this repo has no such note, the code and `AGENTS.md` are the source.
