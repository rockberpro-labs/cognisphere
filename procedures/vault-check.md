# vault-check

Read-only; `/cognisphere:update` runs it. **Never create, edit, move or delete anything
under `~/Cognisphere/`, nor in the three local files.** Each finding names the path, what
is wrong, the expected value, and the fix for the user to apply: by hand, or by running
`/cognisphere:install`, which only creates what is missing (`vault.md`).

```bash
bash "<plugin>/scripts/names.sh"   # main, project, vault (absolute), vault_tilde, vault_exists
```

**Which name.** Expected: `project` as printed. When `AGENTS.local.md` and
`settings.local.json` both name the same other `~/Cognisphere/<name>` and that folder
exists, it is a name chosen at install: accept it, say so in one line, and check against
it (`names.sh <name>` prints its paths).

1. **Vault.**
   - `$vault` missing → report: restore it from the backup (`~/Cognisphere/README.md`), or
     run `/cognisphere:install` to re-seed it. Stop the vault checks there.
   - `$vault/Human/` missing → report the same way.
   - `$vault/Agent/00 Home.md`, the four folders (`State`, `Workflow`, `Log`, `Scratch`)
     and each template note (every file of `<plugin>/templates/vault/Agent/`
     but `{{…}}`) — missing ones are listed: restore from the backup, or
     `/cognisphere:install` re-seeds them (it never touches existing notes). The agent may
     have restructured `Agent/` on purpose: say to check the Log before re-seeding.
   - `Log/` empty → report.
   - **The v0.1.0 layout**, which copied the repo into the vault. Each finding is
     reported, never fixed here:
     - `State/Current State.md`, `Workflow/Working Agreement.md`,
       `Workflow/Review Checklist.md` or `Knowledge/` present → they restate git,
       `AGENTS.md`, the rules and the memory notes. Fix: move what exists nowhere else (a
       decision → History, an open question → Open Threads, a code defect → an issue
       linked from its memory note), then delete them and fix the links to them.
     - `Workflow/Vault Guide.md` with a `Bootstrap` section, or `Workflow/Session
       Protocol.md` with a `## Commands` section → an old template holding no project
       state. Fix: delete it and run `/cognisphere:install`, which re-seeds it.
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
   - Broken `[[links]]`: `perl "<plugin>/scripts/check-links.pl" "$vault/Agent"` prints
     each one. Report them; the agent fixes them in a normal session, not here.
2. **`.agents/settings.local.json`.**
   - Missing → report; `/cognisphere:install` creates it. Not valid JSON → report.
   - `permissions.additionalDirectories` holds `~/Cognisphere/<project>` (or its absolute
     form); `allow` holds `Read(~/Cognisphere/<project>/**)` and
     `Edit(~/Cognisphere/<project>/Agent/**)`; `deny` holds
     `Edit(~/Cognisphere/<project>/Human/**)`. Each missing entry → report it with the
     expected value.
   - An entry naming another dir (the old `~/Obsidian/Vaults/Cognisphere/Projects/<p>`
     layout, a renamed project) → report it next to the expected value.
   - `Write(...)` rules → report them as inert (they never match; `Edit` covers the Write
     tool). Do not remove them.
3. **`AGENTS.local.md`.** Missing → report (`/cognisphere:install` creates it). Its
   `## Agent workspace` section must name `$vault` (absolute, as `names.sh` prints it);
   missing section or another path → report the expected text. An MSYS-style path
   (`/c/Users/...`, from installs before v0.4.0) is a finding too: the Read tool cannot
   open it. A section still mentioning `status: skeleton` or `§ 4 Bootstrap` is the
   v0.1.0 text → report the template's current section. No `## Working style` section →
   report.
4. **`CLAUDE.local.md`** must be a symlink to `AGENTS.local.md`
   (`[ -L CLAUDE.local.md ] && [ "$(readlink CLAUDE.local.md)" = AGENTS.local.md ]`).
   Missing → `/cognisphere:install` creates it; a regular file or another target → report.

Nothing wrong → one line: "vault and local configuration: nothing to do".
