#!/usr/bin/env bash
# names.sh [--project <dir>] [project]: the names every vault step uses (procedures/vault.md
# § Names). With --project, a sub-project (D38): the vault is still the root's, named
# after the root's main worktree, and repo_layer is the sub-project's own.
# Run it to print them; the other scripts source it for the same values and for fill().
sub=; [ "${1:-}" = --project ] && { sub="${2:?usage: names.sh [--project <dir>] [project]}"; shift 2; }
. "$(dirname "${BASH_SOURCE[0]}")/target.sh"; target "$sub" || exit 1
main="$(dirname "$(git -C "$top" rev-parse --path-format=absolute --git-common-dir)")" || exit 1  # main worktree
project="${1:-$(basename "$main")}"       # all worktrees share one vault
root="$HOME/Cognisphere"                  # README.md, Projects/, Shared/ (D32)
# Git Bash's $HOME is /c/Users/...; the Read tool needs C:/Users/...
if command -v cygpath >/dev/null 2>&1; then main="$(cygpath -m "$main")"; root="$(cygpath -m "$root")"; fi
vault="$root/Projects/$project"
vault_tilde="~/Cognisphere/Projects/$project"   # settings.local.json uses the ~/ form
plugin="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Whose repo layer (D31): "cognisphere" when its anti-drift rule is in place, else
# "untouched" (another tool's harness, or none): the vault's local files then stay out
# of everything git tracks. A previous run's § Repo layer keeps it untouched.
if ! grep -qx '## Repo layer' "$dir/AGENTS.local.md" 2>/dev/null \
   && grep -qF '/cognisphere:update' "$dir/.agents/rules/memory.md" 2>/dev/null; then
  repo_layer=cognisphere; else repo_layer=untouched; fi

export CS_PROJECT="$project" CS_DATE="$(date +%F)" CS_MONTH="$(date +%Y-%m)" \
       CS_REPO="$main" CS_VAULT="$vault" CS_ROOT="$root" CS_STYLE="${CS_STYLE:-}"
# fill <template>: the template on stdout, mechanical placeholders replaced.
fill() { perl -pe 's/\{\{project\}\}/$ENV{CS_PROJECT}/g; s/\{\{date\}\}/$ENV{CS_DATE}/g;
  s/\{\{month\}\}/$ENV{CS_MONTH}/g; s/\{\{repo\}\}/$ENV{CS_REPO}/g;
  s/\{\{working_style\}\}/$ENV{CS_STYLE}/g; s/\{\{vault\}\}/$ENV{CS_VAULT}/g;
  s/\{\{root\}\}/$ENV{CS_ROOT}/g' "$1"; }

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  printf 'main=%s\nproject=%s\nroot=%s\nvault=%s\nvault_tilde=%s\nrepo_layer=%s\n' \
    "$main" "$project" "$root" "$vault" "$vault_tilde" "$repo_layer"
  [ "$layout" = root ] || printf 'dir=%s\nlayout=%s\ntag=%s\n' "$dir" "$layout" "$tag"
  [ -d "$vault" ] && echo "vault_exists=yes" || echo "vault_exists=no"
  # A vault from before D32, straight under the root: vault-check.md reports the move.
  if [ -d "$root/$project/Agent" ]; then echo "old_vault=$root/$project"; fi
fi
