#!/usr/bin/env bash
# names.sh [project]: the names every vault step uses (procedures/vault.md § Names).
# Run it to print them; the other scripts source it for the same values and for fill().
main="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" || exit 1  # main worktree
project="${1:-$(basename "$main")}"       # all worktrees share one vault
vault="$HOME/Cognisphere/$project"
# Git Bash's $HOME is /c/Users/...; the Read tool needs C:/Users/...
if command -v cygpath >/dev/null 2>&1; then main="$(cygpath -m "$main")"; vault="$(cygpath -m "$vault")"; fi
vault_tilde="~/Cognisphere/$project"      # settings.local.json uses the ~/ form
plugin="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CS_PROJECT="$project" CS_DATE="$(date +%F)" CS_MONTH="$(date +%Y-%m)" \
       CS_REPO="$main" CS_VAULT="$vault" CS_STYLE="${CS_STYLE:-}"
# fill <template>: the template on stdout, mechanical placeholders replaced.
fill() { perl -pe 's/\{\{project\}\}/$ENV{CS_PROJECT}/g; s/\{\{date\}\}/$ENV{CS_DATE}/g;
  s/\{\{month\}\}/$ENV{CS_MONTH}/g; s/\{\{repo\}\}/$ENV{CS_REPO}/g;
  s/\{\{working_style\}\}/$ENV{CS_STYLE}/g; s/\{\{vault\}\}/$ENV{CS_VAULT}/g' "$1"; }

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  printf 'main=%s\nproject=%s\nvault=%s\nvault_tilde=%s\n' "$main" "$project" "$vault" "$vault_tilde"
  [ -d "$vault" ] && echo "vault_exists=yes" || echo "vault_exists=no"
fi
