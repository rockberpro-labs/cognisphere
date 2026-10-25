# vault

The vault is the unversioned half of the harness: a per-project folder outside the repo,
at `~/Cognisphere/<project>/`, with `Agent/` (the agent's workspace, the agent is the only
writer) and `Human/` (the maintainer's notes, the agent only reads). The local
configuration points the agent at it: `.agents/settings.local.json`, `AGENTS.local.md`
and `CLAUDE.local.md`, all gitignored.

Who writes what:

- `/cognisphere:install` runs § Seed, § Configure and § Fill. It only **creates what is
  missing**: it never modifies an existing vault file, and touches an existing local file
  only to add what that file lacks.
- `/cognisphere:update` runs § Check only. It **never writes** under `~/Cognisphere/` or to
  the local configuration: it reports, and the user fixes by hand or re-runs install.
- After install, the vault belongs to the maintainer and the agent: the agent maintains
  and may restructure `Agent/` through its Session Protocol. The plugin never does.

Everything here is in English, whatever the project's language (`scaffold.md`
§ Language); domain terms stay as the code names them.

## Names

```bash
main="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"  # main worktree
project="$(basename "$main")"            # all worktrees share one vault
vault="$HOME/Cognisphere/$project"      # absolute: AGENTS.local.md and the scripts here
vault_tilde="~/Cognisphere/$project"    # settings.local.json uses the ~/ form
```

The path is fixed: there is no setting for it. The one choice is the name. If `$vault`
already exists and this repo's local configuration does not point at it, another repo
may own it: install asks whether to reuse it or pick another name, and the chosen name
replaces `project` for the whole run (§ Check accepts it later, see there).

## Working style

Asked once, at install. The answer is written, word for word, into `AGENTS.local.md`
§ Working style (through `{{working_style}}`), its only home: the vault points there.

- **Author:** "The agent writes and edits code when asked, following the project's rules,
  and proposes before large or risky changes."
- **Tutor, not author:** "The maintainer writes the code to learn. Explain trade-offs,
  review, catch what a second reviewer would, sketch diffs — but the maintainer
  implements. Don't edit repo files unless explicitly asked."

## Seed

Copies `<plugin>/templates/vault/` into the vault, replacing the mechanical placeholders.
**Create only; never overwrite.**

The vault holds only what nothing else holds: a copy of git state, `AGENTS.md`, the rules
or the memory notes is read twice and drifts the first time the original changes. So no
note copies them, and the templates are complete as seeded: nothing waits to be filled.
`Workflow/Vault Guide.md` carries the rules.

| Placeholder | Value |
|---|---|
| `{{project}}` | `$project` |
| `{{date}}` / `{{month}}` | today, `YYYY-MM-DD` / `YYYY-MM` |
| `{{repo}}` | `$main`, the absolute path of the main worktree |
| `{{working_style}}` | the text chosen above (only in `AGENTS.local.md`, § Configure) |
| `{{vault}}` | `$vault` (only in `AGENTS.local.md`, § Configure) |

```bash
tpl="<plugin>/templates/vault"
export CS_PROJECT="$project" CS_DATE="$(date +%F)" CS_MONTH="$(date +%Y-%m)" \
       CS_REPO="$main" CS_VAULT="$vault" CS_STYLE="<the working style text>"
fill() { perl -pe 's/\{\{project\}\}/$ENV{CS_PROJECT}/g; s/\{\{date\}\}/$ENV{CS_DATE}/g;
  s/\{\{month\}\}/$ENV{CS_MONTH}/g; s/\{\{repo\}\}/$ENV{CS_REPO}/g;
  s/\{\{working_style\}\}/$ENV{CS_STYLE}/g; s/\{\{vault\}\}/$ENV{CS_VAULT}/g' "$1"; }
seed() { if [ -e "$2" ]; then echo "exists  $2"; else
  mkdir -p "$(dirname "$2")" && fill "$1" > "$2" && echo "created $2"; fi; }

seed "$tpl/README.md"       "$HOME/Cognisphere/README.md"
seed "$tpl/Human/README.md" "$vault/Human/README.md"
( cd "$tpl/Agent" && find . -type f ! -name '{{*' ) | sed 's|^\./||' | while IFS= read -r f; do
  seed "$tpl/Agent/$f" "$vault/Agent/$f"
done
seed "$tpl/Agent/Log/{{date}}.md" "$vault/Agent/Log/$CS_DATE.md"
```

Keep the `created` lines: § Fill works on those files only. An `exists` line is left
exactly as it is.

`Human/README.md` is written only here, before § Configure adds the deny rule. On a
re-seed the deny rule may already be in force and block it: report that, and tell the
user to copy `<plugin>/templates/vault/Human/README.md` by hand if they want it.

## Configure

The three local files. Each is created when missing; an existing one only gains what it
lacks. Nothing in them is ever rewritten.

1. **`.agents/settings.local.json`** — the entries of
   `<plugin>/templates/settings.local.json`, with `{{project}}` replaced. Merge: add each
   `additionalDirectories`, `allow` and `deny` entry that is missing; everything else
   stays. Not valid JSON → report it and stop; do not hand-edit around it. Never add
   `Write(...)` rules: they never match (`Edit` rules cover the Write tool).

   ```bash
   f=.agents/settings.local.json
   [ -e "$f" ] || printf '{}\n' > "$f"
   CS_V="~/Cognisphere/$project" perl -MJSON::PP -0777 -ne '
     my $d = eval { JSON::PP->new->decode($_) };
     ref $d eq "HASH" or do { print STDERR "not valid JSON: $ARGV\n"; exit 2 };
     my $v = $ENV{CS_V}; my $p = $d->{permissions} //= {}; my $added = 0;
     my %want = (additionalDirectories => [$v],
                 allow => ["Read($v/**)", "Edit($v/Agent/**)"],
                 deny  => ["Edit($v/Human/**)"]);
     for my $k (sort keys %want) { my $l = $p->{$k} //= [];
       for my $e (@{$want{$k}}) { next if grep { $_ eq $e } @$l; push @$l, $e; $added++ } }
     print JSON::PP->new->pretty->canonical->indent_length(2)->space_before(0)->encode($d) if $added;
   ' "$f" > "$f.new" && [ -s "$f.new" ] && mv "$f.new" "$f"; rm -f "$f.new"
   ```

   "not valid JSON" → stop the step and report; the file is untouched. No output and no
   error → every entry was already there; the file is untouched too.

2. **`AGENTS.local.md`** at the repo root, from `<plugin>/templates/AGENTS.local.md`
   through `fill` (`{{working_style}}` and `{{vault}}`, the **absolute** path: the Read
   tool needs it).
   - Missing → create it. A regular `CLAUDE.local.md` exists and `AGENTS.local.md` does
     not → move it (`mv CLAUDE.local.md AGENTS.local.md`, it is untracked) and treat it
     as existing.
   - Existing → append each section it lacks (`## Working style`, `## Agent workspace`),
     taken from the filled template; the sections it has stay as they are, even when
     they disagree (§ Check reports that).

3. **`CLAUDE.local.md`** → a symlink to `AGENTS.local.md`, mirroring `CLAUDE.md`.
   No tool reads `AGENTS.local.md` natively; this is the bridge.

   ```bash
   if [ -L CLAUDE.local.md ] && [ ! -e CLAUDE.local.md ]; then rm CLAUDE.local.md; fi
   [ -e CLAUDE.local.md ] || ln -s AGENTS.local.md CLAUDE.local.md
   ```

   `CLAUDE.local.md` is a regular file next to an `AGENTS.local.md` → diff them, show
   what only `CLAUDE.local.md` has, and **ask** before merging it in and replacing it
   with the link.

Both root files are in the root `.gitignore` (`scaffold.md` step 5); `settings.local.json`
is in `.agents/.gitignore`. Check with `git check-ignore -q` and report if one is not.

The allow rules and `additionalDirectories` apply only once the folder is trusted:
`.claude` is a symlink, so Claude Code treats `settings.local.json` as supplied by the
repo. Deny rules always apply. The install report says so.

## Fill

Writes what this install run found, into the notes § Seed **created in this run** —
never one that existed. Nothing is copied from the repo: what `AGENTS.md`, `.agents/` or
git already hold stays there.

- **`State/Open Threads.md`**: one numbered item per open question the memory and rules
  passes could not answer (§ Direction), per doc found contradicting the code while
  mapping (§ Direction, until the doc is fixed), and per harness step left undone or
  failed (§ Harness). Each with its evidence. Nothing found → the note stays as seeded.
  A defect in the code is not a thread: list it in the report, for an issue.
- **`Log/<today>.md` § Session 1**: Found (what the passes showed, in a line or two),
  Changed (the vault and local configuration files created; repo files are git's, once
  committed), Not verified (each check not run), Next (the open threads, by number).
- **No invention.** Never a PR number, a date, a figure or a rule the run did not see.
- **Links.** Every `[[link]]` outside code must resolve to a note:

  ```bash
  cd "$vault/Agent" && perl -MFile::Find -0777 -e '
    find(sub { push @f, $File::Find::name if /\.md$/ }, ".");
    for (@f) { (my $n = $_) =~ s/^\.\/|\.md$//g; $n{$n} = $n{(split m|/|, $n)[-1]} = 1 }
    for my $f (@f) { open my $h, "<", $f or next; local $_ = <$h>;
      s/```.*?```//gs; s/`[^`\n]*`//g;
      while (/\[\[([^\]|#\\]+)/g) { print "$f: [[$1]]\n" unless $n{$1} } }'
  ```

  Empty output = all links resolve. Links inside code (the Vault Guide's examples) are
  not links.

## Check

Read-only; `/cognisphere:update` runs it. **Never create, edit, move or delete anything
under `~/Cognisphere/`, nor in the three local files.** Each finding names the path, what
is wrong, the expected value, and the fix for the user to apply.

**Which name.** Expected: `$project` from § Names. When `AGENTS.local.md` and
`settings.local.json` both name the same other `~/Cognisphere/<name>` and that folder
exists, it is a name chosen at install: accept it, say so in one line, and check against it.

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
   `## Agent workspace` section must name `$vault` (absolute); missing section or another
   path → report the expected text. A section still mentioning `status: skeleton` or
   `§ 4 Bootstrap` is the v0.1.0 text → report the template's current section. No
   `## Working style` section → report.
4. **`CLAUDE.local.md`** must be a symlink to `AGENTS.local.md`
   (`[ -L CLAUDE.local.md ] && [ "$(readlink CLAUDE.local.md)" = AGENTS.local.md ]`).
   Missing → `/cognisphere:install` creates it; a regular file or another target → report.

Nothing wrong → one line: "vault and local configuration: nothing to do".
