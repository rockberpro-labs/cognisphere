# review-settings

The project carries its guards: `.agents/hooks/guard.sh`, a copy of the plugin's
`hooks/guard.sh`, registered in `.agents/settings.json` with the checks the team turned
off as flags (D37). They run for everyone on the repo, plugin or not; the plugin runs
none. `.agents/settings.json` also denies blind `git add` and, when the team chose so,
turns off agent co-author attribution. It never names this plugin: a project's config
holds the project's policy, not the tool that wrote it.

`/cognisphere:update` runs this pass after the structure pass, so `.agents/` exists.
`.agents/settings.local.json` is not reviewed here: it is personal, and `vault-check.md`
only reports on it.

Language: nothing here writes prose, only JSON keys.

## Steps

1. **`settings.json`** against `<plugin>/templates/settings.json`:
   - missing → copy the template.
   - present → add only what it lacks: each `deny` entry, and each read-only git
     `allow` entry (`git status`, `git diff`, `git log`, `git show`). Everything else
     stays, in its order. Not
     valid JSON → report it and stop; do not hand-edit around it.
   - `includeCoAuthoredBy` present → it is deprecated: propose the equivalent — `false`
     → `"attribution": { "commit": "", "pr": "" }`, `true` → drop the key — and change
     it only on a yes.
   - `attribution` is the user's choice, not a default to restore. Compare it with the
     co-author bullet of `rules/commit.md`: they disagree (an empty `attribution` but a
     rule that keeps co-authors, or the reverse) → show both and ask which one holds,
     in the user's language; fix the other only on that answer. `commit.md` says
     nothing about co-authors → leave `attribution` as it is; `review-rules.md` asks.
   - entries older tools wrote about themselves — the `agent-kit` or `univates.br` key in
     `extraKnownMarketplaces`, `agent-kit@agent-kit` or `agent-kit@univates.br` in
     `enabledPlugins` → list them and propose removing them; remove only on a yes.
     cognisphere replaces agent-kit, and with both installed every guard runs twice.
     Never add entries for cognisphere. Drop an object left empty. The repo's own
     guard (step 2) keeps the checks running for teammates without either plugin.

2. **The repo's guard** — `bash "<plugin>/scripts/guards.sh" --check`, then by line:
   - `current` and `registered …` → nothing to do; say which checks the flags turn off.
   - `differs` → an older copy, or one the team changed: show `diff` against
     `<plugin>/hooks/guard.sh` and, on a yes, run `scripts/guards.sh` (it replaces the
     copy and keeps the registration). A copy changed on purpose is the team's: leave it.
   - `missing` with `registered` → the registration runs nothing: on a yes, run
     `scripts/guards.sh` to restore the copy.
   - `unregistered` → the repo carries no guards (the team removed them, or a version
     before D37 set it up, when the plugin ran them). Ask the harness's guard question
     (`skills/harness/SKILL.md` § 0, every box checked by default) and run
     `scripts/guards.sh` with its flags; nothing checked → leave it, and report that the
     repo runs no guards.
   - `old .agents/hooks/<guard>.sh` → agent-kit's one-guard-per-file copies, and the
     `PreToolUse` entries that run them: the same checks, older. On a yes, delete them
     and their registrations, and register `guard.sh` instead, the flags matching the
     checks those copies ran. A symlink points at another package: report it with its
     target, never write through it.

3. **Stage** what changed, by name:

   ```bash
   git add .agents/settings.json .agents/hooks/guard.sh   # plus each removed copy: git rm .agents/hooks/<guard>.sh
   ```

4. **Report**: added, removed, left on purpose. Hooks in the project that are not this
   plugin's (a linter, an encoding guard) are the project's — say they were not touched.
