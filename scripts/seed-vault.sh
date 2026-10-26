#!/usr/bin/env bash
# seed-vault.sh <project>: procedures/vault.md § Seed. Copies templates/vault/ into
# ~/Cognisphere/<project>/ with the placeholders filled. Create only, never overwrite:
# one "created" or "exists" line per note; § Fill works on the "created" ones only.
. "$(dirname "$0")/names.sh" "${1:?usage: seed-vault.sh <project>}" || exit 1
tpl="$plugin/templates/vault"
seed() { if [ -e "$2" ]; then echo "exists  $2"; else
  mkdir -p "$(dirname "$2")" && fill "$1" > "$2" && echo "created $2"; fi; }

seed "$tpl/README.md"       "$(dirname "$vault")/README.md"
seed "$tpl/Human/README.md" "$vault/Human/README.md"
( cd "$tpl/Agent" && find . -type f ! -name '{{*' ) | sed 's|^\./||' | while IFS= read -r f; do
  seed "$tpl/Agent/$f" "$vault/Agent/$f"
done
seed "$tpl/Agent/Log/{{date}}.md" "$vault/Agent/Log/$CS_DATE.md"
