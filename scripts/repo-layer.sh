#!/usr/bin/env bash
# repo-layer.sh: skills/harness § 4. After the repo layer is set up in a repo that
# /cognisphere:vault had left untouched (D30, D31): drops § Repo layer from
# AGENTS.local.md, and each anchored .git/info/exclude line for a local file that git
# now ignores without it (the .gitignore entries scaffold.sh added) or that no longer
# exists. One line per change. Exit 0 done, 1 not a git repo.
cd "$(git rev-parse --show-toplevel)" || exit 1

if grep -qx '## Repo layer' AGENTS.local.md 2>/dev/null; then
  perl -0pi -e 's/\n*## Repo layer\n.*?(?=\n## |\z)//s; s/\n*\z/\n/' AGENTS.local.md
  echo "removed AGENTS.local.md: ## Repo layer"
fi

exclude="$(git rev-parse --git-path info/exclude)"
[ -f "$exclude" ] || exit 0
grep -E '^/(AGENTS\.local\.md|CLAUDE\.local\.md|[^/]+/settings\.local\.json)$' "$exclude" \
  | while IFS= read -r line; do
  f="${line#/}"
  grep -vxF "$line" "$exclude" > "$exclude.tmp"; cp "$exclude" "$exclude.bak"; mv "$exclude.tmp" "$exclude"
  # Gone, or behind a link (.claude -> .agents): the line matches nothing any more.
  if [ ! -e "$f" ] || [ -L "$(dirname "$f")" ] || git check-ignore -q "$f" 2>/dev/null; then
    rm -f "$exclude.bak"; echo "removed $exclude: $line"
  else mv "$exclude.bak" "$exclude"; echo "kept    $exclude: $line (nothing else ignores it)"; fi
done
exit 0
