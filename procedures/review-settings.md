# review-settings

The guards run from the plugin (`hooks/guard.sh`), for whoever has it installed. What a
project carries is only `.agents/settings.json`, which denies blind `git add` and, when
the team chose so, turns off agent co-author attribution. It never names this plugin: a
project's config holds the project's policy, not the tool that wrote it.

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
     Never add entries for cognisphere. Drop an object left empty. Say that teammates
     who relied on them keep the guards only by installing the plugin themselves
     (README, *Install*).

2. **Guard copies from older versions** — `.agents/hooks/{master,secret,memory-drift}-guard.sh`
   and the `PreToolUse` entries in `settings.json` that run them. With the plugin installed
   they run a second, stale copy of each check. List them and, on a yes, delete the files
   and their registrations; a copy the user changed on purpose is theirs to keep. A symlink
   points at another package: report it with its target, never write through it.

3. **Stage** what changed, by name:

   ```bash
   git add .agents/settings.json    # plus each removed copy: git rm .agents/hooks/<guard>.sh
   ```

4. **Report**: added, removed, left on purpose. Hooks in the project that are not this
   plugin's (a linter, an encoding guard) are the project's — say they were not touched.
