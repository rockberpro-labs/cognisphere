#!/usr/bin/env bash
# configure.sh <project> <style-file>: procedures/vault.md § Configure.
# Creates the three local files or adds what they lack; never rewrites what is there.
# <style-file> holds the working style text, word for word. When the repo layer is not
# cognisphere's (names.sh repo_layer=untouched; D30, D31): settings.local.json goes where
# Claude Code reads it (.claude/, followed through a link), AGENTS.local.md gains
# § Repo layer, and every file is ignored through .git/info/exclude, so git status shows
# nothing new.
# Exit 0 done, 2 settings.local.json is not valid JSON (left untouched), 3 a regular
# CLAUDE.local.md sits next to AGENTS.local.md (ask, then rerun), 4 untouched and git
# tracks one of the three files (nothing written), 1 a symlink could not be made.
here="$(cd "$(dirname "$0")" && pwd)"
CS_STYLE="$(cat "${2:?usage: configure.sh <project> <style-file>}")" || exit 1
. "$here/names.sh" "$1" || exit 1
untouched=; [ "$repo_layer" = untouched ] && untouched=1
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0; keep() { [ "$1" -gt "$rc" ] && rc="$1"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

settings=.agents/settings.local.json
if [ -n "$untouched" ]; then
  dir=.claude; [ -L .claude ] && dir="$(readlink .claude)"; dir="${dir%/}"
  settings="$dir/settings.local.json"
  for f in "$settings" AGENTS.local.md CLAUDE.local.md; do
    git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
      && { echo "tracked by git: $f (repo layer untouched: nothing written)" >&2; exit 4; }
  done
  exclude="$(git rev-parse --git-path info/exclude)"; mkdir -p "$(dirname "$exclude")"
  for f in "$settings" AGENTS.local.md CLAUDE.local.md; do
    git check-ignore -q "$f" 2>/dev/null || grep -qxF "/$f" "$exclude" 2>/dev/null \
      || { printf '/%s\n' "$f" >> "$exclude"; echo "added   $exclude: /$f"; }
  done
  mkdir -p "$dir"
fi

fill "$plugin/templates/settings.local.json" > "$tmp/settings.json"
perl "$here/merge-json.pl" "$settings" "$tmp/settings.json"; keep $?

if [ ! -e AGENTS.local.md ] && [ -f CLAUDE.local.md ] && [ ! -L CLAUDE.local.md ]; then
  mv CLAUDE.local.md AGENTS.local.md && echo "moved   CLAUDE.local.md -> AGENTS.local.md"
fi
sections=("Working style" "Agent workspace"); [ -n "$untouched" ] && sections+=("Repo layer")
fill "$plugin/templates/AGENTS.local.md" > "$tmp/AGENTS.local.md"
# § Repo layer is the template's last section, and only an untouched repo gets it.
[ -n "$untouched" ] || perl -0pi -e 's/\n+## Repo layer\n.*\z/\n/s' "$tmp/AGENTS.local.md"
if [ ! -e AGENTS.local.md ]; then
  cp "$tmp/AGENTS.local.md" AGENTS.local.md && echo "created AGENTS.local.md"
else
  for s in "${sections[@]}"; do
    grep -qxF "## $s" AGENTS.local.md && continue
    { echo; awk -v h="## $s" '$0 == h { p = 1; print; next } p && /^## / { exit } p' "$tmp/AGENTS.local.md"; } >> AGENTS.local.md
    echo "added   AGENTS.local.md: ## $s"
  done
fi

"$here/link.sh" AGENTS.local.md CLAUDE.local.md; keep $?

for f in "$settings" AGENTS.local.md CLAUDE.local.md; do
  git check-ignore -q "$f" || echo "NOT IGNORED $f"
done
exit "$rc"
