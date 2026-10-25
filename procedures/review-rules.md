# review-rules

Review, not creation: `rules/` exists and this pass finds where it stopped matching the
repository. Checking is reading — do not ask to read.

Two kinds of finding, and they are handled differently:

- **Mandatory** (check 1) — a read rule for every note that owns an area. It carries no
  policy, so write or fix it **without asking** and list it in the report.
- **Proposed** (checks 2–8) — everything else. **Ask before writing**, with the list of
  findings and the fix proposed for each; deleting a rule always needs a yes.

No `.agents/rules/commit.md` → the policy and the path-scoped rules are still to be
written: `/cognisphere:update` runs `rules.md` (full pass) instead, which asks the
commit policy and writes the read rules too. A user who declines the commit policy for
now still gets the read rules: they are mandatory and carry no policy.

`rules/memory.md` is the memory contract and `review-memory.md` already brought it in
line with the template; it is not reviewed again here.

## Language

Settled as `scaffold.md` § Language says (the structure pass already did). Every fix you
write goes in it.

## Mandatory — written without asking

1. **Read rules.** Every note that owns an area — `kind: domain` or `paths:` in its
   frontmatter — has its **read rule**: a rule of the same name in `rules/` (or the area
   rule that points at it) whose first line orders reading that note. A `kind: domain`
   note's rule globs cover the whole domain; any other note with `paths:` gets globs
   that cover at least those `paths:`. Missing, without that line, or with globs
   narrower than the note's → write or fix it the way `rules.md` § Read rules says.
   No note declares `kind:` while `domains.md` maps several domains → this check cannot
   run on those notes: `review-memory.md` check 6 asks which are domains, and this
   check writes their rules after the answer. Never guess from filenames.

## Proposed — written on a yes

Run all of them, then report once.

2. **Commit policy.** `rules/commit.md` against the last few hundred
   `git log --format=%s` subjects; a rule the history contradicts is a question for the
   user, not a silent fix. Missing one of the bullets `rules.md` always includes →
   propose adding it, translated.
   - `rules/commit.md` says nothing about agent co-authors → ask the user, in their
     language, whether commits and PRs made with an agent (Claude, Codex, ...) keep the
     agent as co-author or turn it off — propose what `git log --format=%B` shows, never
     decide it. Write the answer the way `rules.md` does: the bullet in `commit.md` and
     the matching `attribution` in `settings.json`. An old "never co-author" bullet a
     previous version added unasked → confirm it is still wanted. The bullet is not a
     duplicate of `attribution`: that setting binds Claude Code only.
   - A read rule whose note is gone, or no longer declares `kind: domain` or `paths:`
     → propose deleting it.

3. **Globs.** For each rule with `paths:`, how many files each glob matches:

   ```bash
   git ls-files ':(glob)<glob>' | wc -l   # git does not expand {a,b}: check each alternative
   ```

   Zero → the area moved or is gone: fix the glob or propose deleting the rule. A large
   share of the repository → an always-on rule in disguise: narrow it or justify it.

4. **Duplicates.** A rule restating `AGENTS.md` or another rule → keep one, delete the
   other: the same instruction in two places is the shortest path to contradictory
   instructions. A rule repeating what a hook already enforces with a clear message →
   keep only what the hook does not cover.

5. **Size.** Past fifteen imperative lines → the excess is explanation: move it into the
   area's note and leave the pointer.

6. **Pointers.** Every rule ends pointing at a note; the note exists. A broken pointer →
   fix it, or the note is missing: offer `/cognisphere:update <area>`.

7. **Language.** A rule not in the declared language → list it and offer to translate
   (it is a rewrite).

8. **New candidates.** Notes changed since the rule of their area (or with no rule) that
   now carry a prohibition or mandatory step ("never", "always", "before X do Y"):

   ```bash
   git log --format=%h -1 -- .agents/rules/<area>.md     # then compare with the note's
   git log --format=%h -1 -- .agents/memory/<note>.md
   ```

   List them and offer `/cognisphere:update <area>`; do not write them in this pass.

To switch a rule off without deleting it (e.g. only locally), `claudeMdExcludes` in
`.agents/settings.local.json` accepts its path — offer that when the user hesitates
between keeping and deleting; the user adds it there by hand (this plugin never edits
the local configuration after install).

## Report

The read rules written or fixed without asking, then created/changed/deleted rules with
their globs and match counts, what you left and why, and the `/cognisphere:update <area>`
follow-ups. Stage the rules you changed by name.
