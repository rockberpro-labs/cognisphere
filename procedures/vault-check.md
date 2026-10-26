# vault-check

Read-only; `/cognisphere:update` runs it. **Never create, edit, move or delete anything
under `~/Cognisphere/`, nor in the three local files, nor in the user-level settings
(`~/.claude/settings.json`).** Each finding names the path, what is wrong, the expected
value, and the fix for the user to apply: by hand, or by running
`/cognisphere:vault`, which only creates what is missing (`vault.md`).

```bash
bash "<plugin>/scripts/names.sh"   # main, project, root, vault (absolute), vault_tilde, repo_layer, vault_exists, old_vault
```

**No vault.** `AGENTS.local.md` missing, or without `## Agent workspace` → this user
has no vault (D31): a choice, not a defect. Skip steps 1–4 with one line, "no vault —
`/cognisphere:vault` sets one up", and run step 5. Exception: `vault_exists=yes`, or a
`settings.local.json` (`.agents/` or `.claude/`) names `~/Cognisphere/` → a vault the
configuration lost: report it, and that `/cognisphere:vault` reconnects it without
touching its notes.

**Which name.** Expected: `project` as printed. When `AGENTS.local.md` and
`settings.local.json` both name the same other `~/Cognisphere/Projects/<name>` and that folder
exists, it is a name chosen at install: accept it, say so in one line, and check against
it (`names.sh <name>` prints its paths).

1. **Vault.**
   - `old_vault` printed (a vault from before D32, at `~/Cognisphere/<project>/`) → report
     the move, for the user to run, and stop the vault checks there:
     `mkdir -p ~/Cognisphere/Projects && mv ~/Cognisphere/<project> ~/Cognisphere/Projects/`,
     then remove the old `~/Cognisphere/<project>` entries from `settings.local.json`
     and the old `## Agent workspace` section from `AGENTS.local.md`, and run
     `/cognisphere:vault`, which writes the new ones. Notes kept straight under the root
     that should serve every project go in `~/Cognisphere/Shared/`.
   - `$vault` missing → report: restore it from the backup (`~/Cognisphere/README.md`), or
     run `/cognisphere:vault` to re-seed it. Stop the vault checks there.
   - `$vault/Human/` missing → report the same way.
   - `$vault/Agent/00 Home.md`, the four folders (`State`, `Workflow`, `Log`, `Scratch`)
     and each template note (every file of `<plugin>/templates/vault/Agent/`
     but `{{…}}`) — missing ones are listed: restore from the backup, or
     `/cognisphere:vault` re-seeds them (it never touches existing notes). The agent may
     have restructured `Agent/` on purpose: say to check the Log before re-seeding.
   - `Log/` empty → report.
   - **The v0.1.0 layout**, which copied the repo into the vault. Each finding is
     reported, never fixed here:
     - `State/Current State.md`, `Workflow/Working Agreement.md`,
       `Workflow/Review Checklist.md` or `Knowledge/` present → they restate git,
       `AGENTS.md`, the rules and the memory notes. Fix: move what exists nowhere else (a
       decision → History, an open question → Open Threads, a code defect without an
       issue → Findings), then delete them and fix the links to them.
     - `Workflow/Vault Guide.md` with a `Bootstrap` section, or `Workflow/Session
       Protocol.md` with a `## Commands` section → an old template holding no project
       state. Fix: delete it and run `/cognisphere:vault`, which re-seeds it.
     - `00 Home.md` with `## Quick facts`, `State/Open Threads.md` with `## Code`, or any
       note with `status: skeleton` → bring it in line with
       `<plugin>/templates/vault/Agent/` by hand: these hold project state, so no re-seed.

     ```bash
     cd "$vault/Agent" && { ls -d "State/Current State.md" "Workflow/Working Agreement.md" \
       "Workflow/Review Checklist.md" Knowledge 2>/dev/null
       grep -l 'Bootstrap' "Workflow/Vault Guide.md"; grep -l '^## Commands' "Workflow/Session Protocol.md"
       grep -l '^## Quick facts' "00 Home.md"; grep -l '^## Code' "State/Open Threads.md"
       grep -rl '^status: skeleton' .; } 2>/dev/null
     ```
   - The repo keeps a plan or status doc (a pointer note's `doc:`, or one `AGENTS.md`
     names) that the `Workflow/Vault Guide.md` § 1 table does not name → report the row
     to add (`vault.md` § Fill), so the Log and the plan don't both record progress.
   - **Open Harness threads:** list each item under `## Harness` in
     `State/Open Threads.md` that is not struck through. They go stale silently (a
     "not yet trusted" settings file, resolved by the next restart): the agent re-checks
     each one and closes it in a normal session, not here.
   - **Open findings:** count the items under `## Open` in `State/Findings.md` and give
     the oldest "Seen" date, in one line, for the maintainer to triage. Not a defect of
     the vault: never ask to close them here.

     ```bash
     sed -n '/^## Open/,/^## /p' "$vault/Agent/State/Findings.md" | grep -c '^### [0-9]'
     ```
   - Broken `[[links]]`: `perl "<plugin>/scripts/check-links.pl" "$vault/Agent"` prints
     each one. Report them; the agent fixes them in a normal session, not here.
2. **The local settings** — `.agents/settings.local.json`; with `## Repo layer` in
   `AGENTS.local.md`, `.claude/settings.local.json` (inside the directory `.claude` links
   to, when it is a link).
   - Missing → report; `/cognisphere:vault` creates it. Not valid JSON → report.
   - Each entry of `<plugin>/templates/settings.local.json`, `{{project}}` filled: the
     vault and `~/Cognisphere/Shared` in `permissions.additionalDirectories` (or their
     absolute form); `Read` on both and `Edit` on the vault's `Agent/**` in `allow`;
     `Edit` on the vault's `Human/**` and on `Shared/**` in `deny`. Each missing entry →
     report it with the expected value.
   - An entry naming another dir (the pre-D32 `~/Cognisphere/<p>`, the old
     `~/Obsidian/Vaults/Cognisphere/Projects/<p>` layout, a renamed project) → report it
     next to the expected value.
   - A `Read` rule or additional directory covering the whole root (`~/Cognisphere` or
     `~/Cognisphere/**`) or `Projects/` → report it: it lets the agent read every
     project's vault (D32).
   - `Write(...)` rules → report them as inert (they never match; `Edit` covers the Write
     tool). Do not remove them.
   - A hook in it that duplicates one in `settings.json`, or that `AGENTS.md` says not
     to install → report it: it runs twice, or against the project's own rule. Other
     local hooks are the maintainer's business: don't list them.
3. **`AGENTS.local.md`.** Its `## Agent workspace` section must name `$vault` (absolute, as `names.sh` prints it);
   another path → report the expected text. An MSYS-style path
   (`/c/Users/...`, from installs before v0.4.0) is a finding too: the Read tool cannot
   open it. A section still mentioning `status: skeleton` or `§ 4 Bootstrap` is the
   v0.1.0 text → report the template's current section. A section without the
   end-of-session line (`Before the last reply…`, added in v0.5.0) → report the
   template's line: without it nothing makes the agent write the Log, and
   `/cognisphere:vault` never adds a line to an existing section. A section without the
   `Shared/` line (added in v0.11.0) → report the template's line: without it the agent
   neither knows the shared notes exist nor that other projects' folders are off limits. A section without
   the two Findings lines (`When you notice something outside the task…` and
   `Asked about known issues…`, added in v0.7.0) → report the template's lines: without
   them the agent neither records what it notices nor reads it back. A section without
   the Scratch lines (`…/Agent/Scratch/` is your workbench…`, or `is your working memory…`
   before v0.14.0, and the four after it, added in v0.13.0) → report the template's
   lines: without them the agent has no moment to write its working notes and treats
   Scratch as off limits like the rest of `Agent/`. A Scratch line calling it "working
   memory", naming `Scratch/<today> <topic>.md`, without the `This project's working
   state lives in the vault…` line, without `State/Preferences.md`, or ending in "then
   delete the rest" is the v0.13.0 text → report the template's current lines (v0.14.0):
   without them the agent thinks aloud in Scratch instead of keeping its output there,
   writes loose notes the hooks don't count, deletes the day's history, keeps its working
   state in Claude Code's own stores and has nowhere in the vault for what auto-memory
   kept about the maintainer. No `## Working style` section → report.
4. **`CLAUDE.local.md`** must be a symlink to `AGENTS.local.md`
   (`[ -L CLAUDE.local.md ] && [ "$(readlink CLAUDE.local.md)" = AGENTS.local.md ]`).
   Missing → `/cognisphere:vault` creates it; a regular file or another target → report.
   **Repo layer untouched** (`## Repo layer` in `AGENTS.local.md`): each of the three
   files must be ignored (`git check-ignore -q`) and untracked
   (`git ls-files --error-unmatch` fails); otherwise report it, with the
   `.git/info/exclude` line to add, or that it must leave the index.
5. **User-level settings.** The project's files are not the only place a guard gets
   registered: a plugin or hook enabled for the user runs in every project.

   ```bash
   perl "<plugin>/scripts/user-settings.pl"   # no output = nothing to report; exit 2 = not valid JSON
   ```

   Report each line it prints, with its fix for the user to apply:
   - `agent-kit@…` enabled → every guard runs twice. `/plugin uninstall agent-kit@agent-kit`
     and `/plugin marketplace remove agent-kit`.
   - cognisphere enabled more than once → keep one; `/plugin uninstall` the others.
   - a hook that runs a guard script → a copy older tools installed for the user; the
     plugin already runs it. Remove its entry from `~/.claude/settings.json` by hand. A
     script of the user's own that only shares the name is theirs: say so and leave it.

Nothing wrong → one line: "vault, local and user-level configuration: nothing to do".
