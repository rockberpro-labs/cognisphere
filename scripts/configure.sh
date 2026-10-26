#!/usr/bin/env bash
# configure.sh <project> <style-file>: procedures/vault.md § Configure. Creates the three
# local files or adds what they lack; never rewrites what is there. <style-file> holds
# the working style text, word for word. Exit 0 done, 2 settings.local.json is not valid
# JSON (left untouched), 3 a regular CLAUDE.local.md sits next to AGENTS.local.md (ask,
# then rerun), 1 a symlink could not be made.
here="$(cd "$(dirname "$0")" && pwd)"
CS_STYLE="$(cat "${2:?usage: configure.sh <project> <style-file>}")" || exit 1
. "$here/names.sh" "$1" || exit 1
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0; keep() { [ "$1" -gt "$rc" ] && rc="$1"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

fill "$plugin/templates/settings.local.json" > "$tmp/settings.json"
perl "$here/merge-json.pl" .agents/settings.local.json "$tmp/settings.json"; keep $?

if [ ! -e AGENTS.local.md ] && [ -f CLAUDE.local.md ] && [ ! -L CLAUDE.local.md ]; then
  mv CLAUDE.local.md AGENTS.local.md && echo "moved   CLAUDE.local.md -> AGENTS.local.md"
fi
fill "$plugin/templates/AGENTS.local.md" > "$tmp/AGENTS.local.md"
if [ ! -e AGENTS.local.md ]; then
  cp "$tmp/AGENTS.local.md" AGENTS.local.md && echo "created AGENTS.local.md"
else
  for s in "Working style" "Agent workspace"; do
    grep -qxF "## $s" AGENTS.local.md && continue
    { echo; awk -v h="## $s" '$0 == h { p = 1; print; next } p && /^## / { exit } p' "$tmp/AGENTS.local.md"; } >> AGENTS.local.md
    echo "added   AGENTS.local.md: ## $s"
  done
fi

"$here/link.sh" AGENTS.local.md CLAUDE.local.md; keep $?

for f in .agents/settings.local.json AGENTS.local.md CLAUDE.local.md; do
  git check-ignore -q "$f" || echo "NOT IGNORED $f"
done
exit "$rc"
