#!/usr/bin/env bash
# scaffold.sh: the mechanical part of procedures/scaffold.md steps 2-5. Create-only:
# one line per item, "created", "exists", "added" or "moved". Exit 0 all done, 3 a real
# .claude/ or CLAUDE.md is in the way (merge it, asking first, then rerun), 2
# settings.json is not valid JSON (left untouched), 1 a symlink could not be made.
here="$(cd "$(dirname "$0")" && pwd)"; plugin="$(dirname "$here")"
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0; keep() { [ "$1" -gt "$rc" ] && rc="$1"; }
copy() { if [ -e "$2" ]; then echo "exists  $2"; else cp "$1" "$2" && echo "created $2"; fi; }

mkdir -p .agents/memory .agents/rules
if [ -e .agents/.gitignore ]; then
  grep -qxF settings.local.json .agents/.gitignore \
    || { echo settings.local.json >> .agents/.gitignore; echo "added   .agents/.gitignore: settings.local.json"; }
else printf 'settings.local.json\n.obsidian\n' > .agents/.gitignore; echo "created .agents/.gitignore"; fi
"$here/link.sh" .agents .claude; keep $?

copy "$plugin/templates/rules/memory.md" .agents/rules/memory.md   # created → translate it
perl "$here/merge-json.pl" .agents/settings.json "$plugin/templates/settings.json"; keep $?

if [ -L CLAUDE.md ] && [ ! -e CLAUDE.md ]; then rm CLAUDE.md; fi   # dangling: drop it
if [ ! -e AGENTS.md ] && [ -f CLAUDE.md ] && [ ! -L CLAUDE.md ]; then
  { git mv CLAUDE.md AGENTS.md 2>/dev/null || mv CLAUDE.md AGENTS.md; } && echo "moved   CLAUDE.md -> AGENTS.md"
fi
[ -e AGENTS.md ] || { touch AGENTS.md; echo "created AGENTS.md (empty)"; }
"$here/link.sh" AGENTS.md CLAUDE.md; keep $?

touch .gitignore
for f in AGENTS.local.md CLAUDE.local.md; do
  grep -qxF "$f" .gitignore || grep -qxF "/$f" .gitignore \
    || { printf '%s\n' "$f" >> .gitignore; echo "added   .gitignore: $f"; }
done
exit "$rc"
