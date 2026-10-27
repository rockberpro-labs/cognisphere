#!/usr/bin/env bash
# PostToolUse hook for Write, Edit and MultiEdit: plan-mirror. Copies a plan-mode plan
# file into today's Scratch/ day folder each time it is written, so the plan lives in
# the vault with the rest of the project's working state (D36). Plan mode keeps writing
# its own file; scratch-redirect leaves that folder alone so plan mode isn't broken.
#
#   Active only when the nearest AGENTS.local.md, from the cwd's repo up, names a vault
#   ("The vault for this project is `…`") that has an Agent/Scratch/ folder.
#   Mirrored: a .md file directly under ${CLAUDE_CONFIG_DIR:-~/.claude}/plans/, copied to
#   Scratch/YYYY-MM-DD/plan <name>.md and replaced on every later write of the plan.
#
# Limit: a `plansDirectory` set in Claude Code's settings isn't followed.
#
# Never blocks: it exits 0 whatever happens.
set -uo pipefail

payload="$(cat)" || exit 0
# cwd and the written path, NUL-separated. perl + JSON::PP, as in guard.sh.
{ IFS= read -r -d '' cwd && IFS= read -r -d '' path; } < <(
  printf '%s' "$payload" | perl -MJSON::PP -0777 -ne '
  my $j = eval { decode_json($_) }; exit 0 unless ref $j eq "HASH";
  my $in = ref $j->{tool_input} eq "HASH" ? $j->{tool_input} : {};
  print join("\0", $j->{cwd} // "", $in->{file_path} // ""), "\0";
' 2>/dev/null) || exit 0
[ -n "$path" ] || exit 0
[ -n "$cwd" ] && { cd "$cwd" 2>/dev/null || exit 0; }

# Git Bash on Windows mixes C:\, C:/ and /c/ forms; cygpath gives one. Elsewhere, as is.
unix() { if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi; }
path="$(unix "$path")"
plans="$(unix "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")/plans"
case "$path" in "$plans"/*/*) exit 0 ;; "$plans"/*.md) ;; *) exit 0 ;; esac
[ -f "$path" ] || exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
root="$(unix "$root")"
# The nearest AGENTS.local.md, from the repo up, names the vault (vault-of.sh).
. "$(dirname "$0")/vault-of.sh"
vault="$(vault_of "$root")"
[ -n "$vault" ] || exit 0
scratch="$(unix "$vault")/Agent/Scratch"
[ -d "$scratch" ] || exit 0

day="$scratch/$(date +%F)"
copy="$day/plan ${path##*/}"
mkdir -p "$day" 2>/dev/null && cp "$path" "$copy" 2>/dev/null || exit 0

# Tell the agent, so it reads and extends the copy instead of starting another note.
perl -MJSON::PP -e 'print encode_json({ hookSpecificOutput => { hookEventName => "PostToolUse",
  additionalContext => "plan-mirror: the plan is copied to $ARGV[0] in the vault; it counts as this task'"'"'s Scratch note and is refreshed on every write of the plan." } })' "$copy" 2>/dev/null
exit 0
