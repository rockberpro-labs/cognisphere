# vault

The vault is the unversioned half of the harness: a per-project folder outside the repo,
at `~/Cognisphere/Projects/<project>/`, with `Agent/` (the agent's workspace, the agent is
the only writer) and `Human/` (the maintainer's notes, the agent only reads). Next to
`Projects/`, `~/Cognisphere/Shared/` holds the maintainer's notes for every project: each
project's agent reads it and none writes there (D32). The rest of the root is the
maintainer's alone, and no agent is granted another project's folder. The local
configuration points the agent at it: `.agents/settings.local.json`, `AGENTS.local.md`
and `CLAUDE.local.md`, all ignored by git. When the repo layer is not cognisphere's
(D30, D31), the settings file is `.claude/settings.local.json` and the ignore lines are in
`.git/info/exclude`; nothing git tracks changes. The vault is personal and optional: a
user without one has none of these files, and `update` treats that as a choice (D31).

Who reads what:

- `/cognisphere:vault` reads this file: § Names, § Working style, § Seed, § Configure,
  § Fill. So does `/cognisphere:install`, after `/cognisphere:harness`. Both
  only **create what is missing**: it never modifies an existing vault file,
  and touches an existing local file only to add what that file lacks.
- `/cognisphere:update` reads `vault-check.md` only, and **never writes** under
  `~/Cognisphere/` or to the local configuration.
- After install, the vault belongs to the maintainer and the agent: the agent maintains
  and may restructure `Agent/` through its Session Protocol. The plugin never does.

The mechanical steps are scripts in `<plugin>/scripts/`: run them, do not retype them.
Everything here is in English, whatever the project's language (`scaffold.md`
§ Language); domain terms stay as the code names them.

## Names

```bash
bash "<plugin>/scripts/names.sh" [<project>]   # prints main, project, root, vault, vault_tilde, vault_exists
```

`project` defaults to the main worktree's folder name, so all worktrees share one vault.
`repo_layer` is `cognisphere` when `.agents/rules/memory.md` names `/cognisphere:update`
and `AGENTS.local.md` has no `## Repo layer`; otherwise `untouched`. § Configure reads it.
`root` (`~/Cognisphere`) and `vault` (`<root>/Projects/<project>`) are absolute and,
under Git Bash, in `C:/...` form, which the Read tool needs. `old_vault` is printed only
when a vault from before D32 sits straight under the root: `vault-check.md` reports the
move; this procedure never moves it.
The path is fixed: there is no setting for it. The one choice is the name. If the vault
already exists and this repo's local configuration does not point at it, another repo
may own it: install asks whether to reuse it or pick another name, and the chosen name is
the `<project>` every script below gets (`vault-check.md` accepts it later).

## Working style

Asked once, at install. The answer is written, word for word, into `AGENTS.local.md`
§ Working style, its only home: the vault points there.

- **Author:** "The agent writes and edits code when asked, following the project's rules,
  and proposes before large or risky changes."
- **Tutor, not author:** "The maintainer writes the code to learn. Explain trade-offs,
  review, catch what a second reviewer would, sketch diffs — but the maintainer
  implements. Don't edit repo files unless explicitly asked."

Write the chosen text to a file in the scratchpad: § Configure reads it from there.

## Seed

Copies `<plugin>/templates/vault/` into the vault, filling `{{project}}`, `{{date}}`,
`{{month}}` and `{{repo}}`; its `README.md` and `Shared/README.md` go to the root, once
for every project. **Create only; never overwrite.**

```bash
bash "<plugin>/scripts/seed-vault.sh" <project>
```

Keep the `created` lines: § Fill works on those files only. An `exists` line is left
exactly as it is.

The vault holds only what nothing else holds: a copy of git state, `AGENTS.md`, the rules
or the memory notes is read twice and drifts the first time the original changes. So no
note copies them, and the templates are complete as seeded: nothing waits to be filled.
`Workflow/Vault Guide.md` carries the rules.

`Human/README.md` and `Shared/README.md` are written only here, before § Configure adds
the deny rules. On a re-seed, or a second project, a deny rule may already be in force
and block one: report that, and tell the user to copy it from
`<plugin>/templates/vault/` by hand if they want it.

## Configure

The three local files. Each is created when missing; an existing one only gains what it
lacks. Nothing in them is ever rewritten.

```bash
bash "<plugin>/scripts/configure.sh" <project> <style-file>
```

- **`.agents/settings.local.json`** gains each entry of
  `<plugin>/templates/settings.local.json` it lacks; its own keys keep their order. Exit 2
  → not valid JSON: stop the step and report; the file is untouched, do not hand-edit
  around it. Never add `Write(...)` rules: they never match (`Edit` rules cover the
  Write tool).
- **`AGENTS.local.md`** at the repo root, from `<plugin>/templates/AGENTS.local.md`.
  Missing → created; a regular `CLAUDE.local.md` with no `AGENTS.local.md` is moved to
  that name first. Existing → each section it lacks (`## Working style`,
  `## Agent workspace`) is appended; the sections it has stay, even when they disagree
  (`vault-check.md` reports that). Created in this run and `AGENTS.md` has its own
  end-of-unit step (update the plan, commit, tell the user to `/clear`) → name that step
  in the end-of-session line, e.g. "…or before telling the user to `/clear`", so the
  vault step rides on the ritual the agent already follows. Only `AGENTS.local.md`
  changes: `AGENTS.md` is shared, and teammates have no vault.
- **`CLAUDE.local.md`** → a symlink to `AGENTS.local.md`, mirroring `CLAUDE.md`. No tool
  reads `AGENTS.local.md` natively; this is the bridge. Exit 3 → a regular
  `CLAUDE.local.md` sits next to `AGENTS.local.md`: diff them, show what only
  `CLAUDE.local.md` has, and **ask** before merging it in, deleting it and rerunning.
- **`repo_layer=untouched`** (another tool's harness, or none): the settings file is
  `.claude/settings.local.json`, or the same name inside the directory `.claude` links to
  (where Claude Code reads it, whichever tool made the link); `AGENTS.local.md` gains
  `## Repo layer`, which tells the agent and `update` that the repo is not cognisphere's
  to change; each file git does not already ignore gets an anchored line in
  `.git/info/exclude` (`git rev-parse --git-path info/exclude`, shared by all
  worktrees). Exit 4 → git tracks one of the three files: nothing was written.
  `repo_layer=cognisphere` → `.agents/settings.local.json`, covered by the `.gitignore`
  entries `scaffold.sh` adds.
- A `NOT IGNORED` line → that file is not ignored by git: report it (`scripts/scaffold.sh`
  adds the entries).

The allow rules and `additionalDirectories` apply only once the folder is trusted
when `.claude` is a symlink: Claude Code then treats `settings.local.json` as supplied
by the repo. Deny rules always apply. The install report says so.

## Fill

Writes what this run found, into the notes § Seed **created in this run** — never one
that existed. Nothing is copied from the repo: what `AGENTS.md`, `.agents/` or git
already hold stays there. A `/cognisphere:vault` run maps nothing: only Session 1, and a
§ Harness thread for each step that failed.

- **`State/Open Threads.md`**: one numbered item per open question the memory and rules
  passes could not answer (§ Direction), per doc found contradicting the code while
  mapping (§ Direction, until the doc is fixed), and per harness step left undone or
  failed (§ Harness), with a follow-up such as the Windows link setup among them. Each
  with its evidence. Nothing found → the note stays as seeded. A defect in the code is
  not a thread: it goes in Findings (next item) and the report. The repo keeps its own
  plan, TODO or issue file → its items stay there: Open Threads links the file once
  (§ Direction) and holds only what it doesn't.
- **`State/Findings.md`**: one numbered item under `## Open` per code defect, risk or
  improvement the mapping passes noticed, in the format its hint comment gives, "while"
  naming the pass (e.g. "while mapping `billing`"), at the commit the run saw. Not a
  scan: only what the passes came across. Nothing noticed → the note stays as seeded.
  An item the repo's plan, TODO or issue tracker already holds stays there.
- **`Workflow/Vault Guide.md` § 1 table**: the memory pass found a plan or status doc
  (`memory.md` phase 0) → replace the generic "Planned work and its status" row with
  rows naming it, one per kind of fact it owns, e.g. `| Phase status, next steps,
  per-phase log | PLAN.md |`. The vault's Log then stays at session level (§ 2 Log).
- **`Log/<today>.md` § Session 1**: Found (what the passes showed, in a line or two),
  Changed (the vault and local configuration files created, and "repo changes
  uncommitted" unless the user had them committed), Not verified (each check not run),
  Next (the open threads, by number).
- **No invention.** Never a PR number, a sha, a date, a figure or a rule the run did not
  see.
- **Links.** Every `[[link]]` outside code must resolve to a note:

  ```bash
  perl "<plugin>/scripts/check-links.pl" "<vault>/Agent"   # no output = all resolve
  ```
