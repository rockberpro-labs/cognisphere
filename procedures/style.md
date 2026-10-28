# style

The working-style switch (D46): `/cognisphere:auto`, `/cognisphere:copilot` and
`/cognisphere:tutor` each run this with their own style. The styles are defined once, in
`<plugin>/templates/styles/<style>.md`; install asks for one (`vault.md` § Working
style), and these commands change it later. The answer lives in `AGENTS.local.md`
§ Working style: gitignored, so it holds for this project and this maintainer only.
`<plugin>` is `${CLAUDE_PLUGIN_ROOT}`.

1. **Switch.**

   ```bash
   cd "$(git rev-parse --show-toplevel)" || exit 1   # not a git repo → stop and say so
   bash "<plugin>/scripts/style.sh" <style>
   ```

   The script finds the nearest `AGENTS.local.md` from the git root up (a sub-project
   switches the root's: that file is the one that loads) and swaps the known style text
   in § Working style, keeping any lines of the maintainer's own around it. No
   `AGENTS.local.md` (a harness-only repo, no vault) → it creates one with only
   § Working style, links `CLAUDE.local.md` to it and makes sure git ignores both.
   - Exit 3 → § Working style holds text of the maintainer's own, none of the known
     styles: show it, word for word, and **ask** whether to replace it. On a yes, rerun
     with `--replace`; on a no, stop.
   - Exit 4 → git tracks `AGENTS.local.md` or `CLAUDE.local.md`: nothing was written.
     Say so and stop; the file is the team's, not the maintainer's.
   - Exit 1 → `CLAUDE.local.md` could not be made a link: say so and point at
     `GUIDE.md` § Windows.
2. **Apply it now.** The file loaded at session start still holds the old style. From
   this reply on, work by `<plugin>/templates/styles/<style>.md`: read it, and it
   replaces § Working style as loaded.
3. **Record it.** `AGENTS.local.md` § Agent workspace names a vault → one line in
   today's `Log/` entry: the switch, from what to what (the script's `switched` line).
   No vault → nothing to record.
4. **Report** in two lines: the switch (`unchanged`, or from what to what), the file, and
   whether it was created; then the new style in one sentence. A new file → it loads by
   itself from the next session. Nothing else changed: never the vault's notes, never
   what git tracks.
