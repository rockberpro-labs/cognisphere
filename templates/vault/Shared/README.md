# Shared

Your notes for every project: conventions, references, snippets, anything an agent should be able to look up whatever repo it works in. Organise it as you like (`Notes/`, `Tools/`, …).

- Every project's agent can read this folder and none can write here (denied in each repo's local `settings.local.json`). Agents read a note here when you point at it or the task needs it; they don't load the folder whole.
- Notes about one project belong in that project's `Projects/<project>/Human/`.
- Anything else at the root of `~/Cognisphere/` is yours alone: no agent is granted it.
- To hand a note to an agent, copy its path in Obsidian and run `/cognisphere:read <path> [what to do]`.
- This folder is not backed up; see `../README.md`.
