# Changelog

What changed in each release of cognisphere. Versions follow
[semver](https://semver.org/); the reasoning behind each change is in
[docs/decisions.md](docs/decisions.md), referenced as `Dnn`.

## Unreleased

### Changed

- The README is now a short introduction (problem, quick start, a session end to end,
  one summary per part), and the reference moved to the new [GUIDE.md](GUIDE.md): every
  command step by step, the guards and their limits, backups, Windows, uninstall,
  language and the repository's contents (D33).
- The README presents the vault as a PKM (Personal Knowledge Management) system: an
  Obsidian AgentOS in plain Markdown that doesn't need Obsidian.
- Symlink failures on Windows point at `GUIDE.md § Windows`.

## 0.11.0 — 2026-10-26

### Changed

- **Vaults moved** from `~/Cognisphere/<project>/` to
  `~/Cognisphere/Projects/<project>/`, so the root no longer mixes generated vaults with
  your own folders. A vault at the old path isn't moved for you: `/cognisphere:update`
  reports the move, and `/cognisphere:vault` stops instead of seeding an empty vault
  beside it (D32).

### Added

- `~/Cognisphere/Shared/` for notes that serve every project: each project's agent may
  read it and is denied writing it. Nothing grants the root, `Projects/` or another
  project's folder.
- `/cognisphere:read` resolves `Projects/<project>/`, `<project>/` and `Shared/` paths,
  and refuses other projects' folders.

## 0.10.1 — 2026-10-26

### Fixed

- Skill descriptions no longer show `&lt;project&gt;` in the skill picker.

## 0.10.0 — 2026-10-26

### Added

- `/cognisphere:harness` sets up only the versioned repo layer, and
  `/cognisphere:vault` only the vault and its local configuration.
  `/cognisphere:install` runs both, asking their questions in one round (D31).
- Running `/cognisphere:harness` in a vault-only repo moves the local configuration
  over to `.agents/`.

### Changed

- No `## Agent workspace` in `AGENTS.local.md` means no vault: `update` and `read` skip
  the vault instead of reporting it missing.
- The README was rewritten around what cognisphere solves; the release gate moved to
  `CONTRIBUTING.md`.

### Removed

- Install's "leave the repo layer untouched" question (from 0.9.0): run
  `/cognisphere:vault` instead.

## 0.9.0 — 2026-10-26

### Added

- Install can leave the repo layer untouched, for repos whose harness belongs to
  someone else: local files go to `.claude/` and are ignored through
  `.git/info/exclude`, so `git status` shows nothing new (D30).
- Install compares `git status` before and after the run and reports any new line.

## 0.8.0 — 2026-10-26

### Added

- `/cognisphere:read <note> [request]` reads a vault note by the path Obsidian copies,
  with its embeds and links one level deep, checks it against the code, then does the
  request. It never writes the note (D28).

## 0.7.0 — 2026-10-26

### Added

- `Agent/State/Findings.md`: the agent records bugs, risks, smells, missing tests and
  ideas it notices outside its task, each anchored to a commit, and reads it first when
  asked for known issues (D27).

## 0.6.0 — 2026-10-26

### Added

- `/cognisphere:update` checks `~/.claude/settings.json` for what would run the guards
  twice: a second plugin with the same guards, cognisphere enabled more than once, a
  guard hook registered for the user. It never writes that file (D26).

## 0.5.0 — 2026-10-26

### Changed

- The agent keeps the vault up to date at the end of each session, and defers to the
  repo's own plan or progress log when there is one (D25).
- Install reports how much of the code the drift guard covers.

### Fixed

- Merging settings keeps key order and number form.

## 0.4.0 — 2026-10-25

### Added

- Install's mechanical steps ship as scripts in `scripts/` (scaffold, seed the vault,
  configure, links, settings merge, link check), with a self-test (D23, D24).
- Pointer notes (`kind: pointer`) adopt an existing doc instead of copying it; the drift
  guard accepts a commit that updates the doc.

### Fixed

- On Windows, links retry with `MSYS=winsymlinks:nativestrict` before stopping, and the
  vault path uses the `C:/` form.

## 0.3.0 — 2026-10-25

### Added

- Windows support under Git Bash (D22).

### Changed

- Install and update are the `/plugin` commands inside Claude Code.

### Fixed

- Install stops when `ln -s` copies instead of linking.

## 0.2.0 — 2026-10-25

### Added

- MIT license.

### Fixed

- The vault is seeded only with what git and the repo don't already hold.

## 0.1.0 — 2026-10-25

First release: the `.agents/` harness (memory catalog, rules, settings), the
`master-guard`, `secret-guard` and `memory-drift-guard` hooks, the per-project vault
with `Agent/` and `Human/`, `/cognisphere:install` and `/cognisphere:update`, and the
explorer, planner, implementer, test-runner and reviewer agents.
