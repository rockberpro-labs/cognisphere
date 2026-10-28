#!/usr/bin/env bash
# configure.sh <project> <style-file>: procedures/vault.md § Configure.
# configure.sh --project <dir> <project>: a sub-project (D38). The vault is the root's,
# so the root must have it configured. Same-repo: nothing to write, the root's files
# apply. Own-repo: only settings.local.json, in the sub-project, since Claude Code reads
# it from the git root; CLAUDE.local.md loads from the folder above.
# Creates the three local files or adds what they lack; never rewrites what is there.
# <style-file> holds the working style text, word for word: templates/styles/<style>.md.
# When the repo layer is not cognisphere's (names.sh repo_layer=untouched; D30, D31):
# settings.local.json goes where Claude Code reads it (.claude/, followed through a link),
# AGENTS.local.md gains § Repo layer, and every file is ignored through .git/info/exclude,
# so git status shows nothing new.
# Exit 0 done, 2 settings.local.json is not valid JSON (left untouched), 3 a regular
# CLAUDE.local.md sits next to AGENTS.local.md (ask, then rerun), 4 untouched and git
# tracks one of the three files (nothing written), 1 a symlink could not be made,
# 5 a sub-project whose root has no vault configured.
here="$(cd "$(dirname "$0")" && pwd)"
if [ "${1:-}" = --project ]; then
  . "$here/names.sh" --project "${2:?usage: configure.sh --project <dir> <project>}" "${3:?usage: configure.sh --project <dir> <project>}" || exit 1
else
  CS_STYLE="$(cat "${2:?usage: configure.sh <project> <style-file>}")" || exit 1
  . "$here/names.sh" "$1" || exit 1
fi
untouched=; [ "$repo_layer" = untouched ] && untouched=1
if [ "$layout" != root ]; then
  grep -qF "The vault for this project is \`$vault\`" "$top/AGENTS.local.md" 2>/dev/null \
    || { echo "the root has no vault at $vault: run /cognisphere:vault at the root first" >&2; exit 5; }
  [ "$layout" = same-repo ] && { echo "covered $tag/: same repo as the root, whose local files apply"; exit 0; }
fi
cd "$dir" || exit 1
rc=0; keep() { [ "$1" -gt "$rc" ] && rc="$1"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

settings=.agents/settings.local.json
# A sub-project has no AGENTS.local.md of its own: the root's loads from the folder above.
extra=(); [ "$layout" = root ] && extra=(AGENTS.local.md CLAUDE.local.md)
if [ -n "$untouched" ]; then
  cdir=.claude; [ -L .claude ] && cdir="$(readlink .claude)"; cdir="${cdir%/}"
  settings="$cdir/settings.local.json"
  for f in "$settings" "${extra[@]}"; do
    git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
      && { echo "tracked by git: $f (repo layer untouched: nothing written)" >&2; exit 4; }
  done
  exclude="$(git rev-parse --git-path info/exclude)"; mkdir -p "$(dirname "$exclude")"
  for f in "$settings" "${extra[@]}"; do
    git check-ignore -q "$f" 2>/dev/null || grep -qxF "/$f" "$exclude" 2>/dev/null \
      || { printf '/%s\n' "$f" >> "$exclude"; echo "added   $exclude: /$f"; }
  done
  mkdir -p "$cdir"
fi

fill "$plugin/templates/settings.local.json" > "$tmp/settings.json"
perl "$here/merge-json.pl" "$settings" "$tmp/settings.json"; keep $?

if [ "$layout" = root ]; then
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
fi

for f in "$settings" "${extra[@]}"; do
  git check-ignore -q "$f" || echo "NOT IGNORED $f"
done
exit "$rc"
