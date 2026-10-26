# Contributing

## Versioning and release gate

`version` in `.claude-plugin/plugin.json` decides whether a machine gets an update.
Without bumping it, every commit counts as a new version. Release flow:

```bash
# 1. change the code on a branch   2. bump version in plugin.json (semver)
claude plugin validate . --strict && claude plugin validate .claude-plugin/plugin.json --strict
for t in hooks/*.test.sh scripts/*.test.sh; do bash "$t" || break; done
# when a skill or procedure changed: the eval fixtures (costs real runs)
claude plugin eval . --scaffold --allow-tools Bash Write Edit --runs 3
# 3. open the PR and merge it   4. tag the merge commit on main
git tag <version> && git push origin <version>
```

There is no CI in this repository on purpose; the lines above are the gate. On each
machine, run `/plugin marketplace update cognisphere` and restart the session.

## What does not belong here

Two things stay in the repository's own `.agents/`:

- **a script that serves only one project** — reading a specific `.ini`, a homegrown
  linter. It becomes a plugin when a second project needs it.
- **a convention** — the commit standard, the target runtime, the encoding, the notes
  and rules the procedures write. That is information about the repo, and it has to be
  readable by whoever clones it without this plugin. The plugin carries the *procedure*;
  the project keeps the *result*. Nothing here ships a pre-filled note or rule. The
  exceptions are `templates/rules/memory.md`, which states how the catalog is kept, and
  the vault templates, which hold only structure and the vault's own rules.

## Design decisions

Record each decision, with what was rejected, in [docs/decisions.md](docs/decisions.md).
