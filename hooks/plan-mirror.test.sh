#!/usr/bin/env bash
# Self-check for the plan-mirror PostToolUse hook:  bash hooks/plan-mirror.test.sh
#
# Runs every case inside a throwaway repo, vault and config dir under $TMPDIR. Exits
# non-zero if any case regresses.
set -uo pipefail

H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plan-mirror.sh"
bash -n "$H" || exit 1
[ -x "$H" ] || { echo "missing exec bit: plan-mirror.sh (git update-index --chmod=+x)"; exit 1; }
perl -MJSON::PP -e1 || { echo "perl with JSON::PP is required (the hook needs it too)"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export TMPDIR="$tmp" HOME="$tmp"   # `~/` and ~/.claude expand here
unset CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR

repo="$tmp/repo"; vault="$tmp/vault"; plans="$tmp/.claude/plans"
copy="$vault/Agent/Scratch/$(date +%F)/plan quiet-river.md"
# A fresh repo, a vault with a Scratch/ folder and a written plan.
# $1 is the path form AGENTS.local.md names.
reset() {
  rm -rf "$repo" "$vault" "$plans"
  mkdir -p "$repo" "$vault/Agent/Scratch" "$plans"
  git -C "$repo" init -q -b feat
  printf '# local\n\n## Agent workspace\n\n- The vault for this project is `%s` (outside the repo).\n' \
    "${1:-$vault}" > "$repo/AGENTS.local.md"
  echo 'PLAN-V1' > "$plans/quiet-river.md"
}

fails=0
# t <name> <copied: yes|no> [file_path] [payload override]
t() {
  local p="${4:-$(printf '{"session_id":"s","cwd":"%s","hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"%s"}}' \
    "$repo" "${3:-$plans/quiet-river.md}")}"
  local out; out="$(printf '%s' "$p" | bash "$H" 2>&1)"; local r=$? s=ok got=no
  [ -f "$copy" ] && got=yes
  { [ "$r" = 0 ] && [ "$got" = "$2" ]; } || { s=FAIL; fails=$((fails+1)); printf '%s\n' "$out" | sed 's/^/       /'; }
  printf '%-4s exit=%s copied=%s  <- %s\n' "$s" "$r" "$got" "$1"
  last_out="$out"
}

echo "== not mirrored =="
reset; rm "$repo/AGENTS.local.md"; t 'no AGENTS.local.md' no
reset /nope/missing; t 'the configured vault has no Scratch/' no
reset; t 'not a git repo' no "" "{\"cwd\":\"$tmp\",\"tool_input\":{\"file_path\":\"$plans/quiet-river.md\"}}"
reset; t 'payload is not JSON' no "" 'not json'
reset; t 'a repo file' no "$repo/a.md"
reset; mkdir -p "$plans/sub"; echo x > "$plans/sub/x.md"; t 'a file in a plans subfolder' no "$plans/sub/x.md"
reset; rm "$plans/quiet-river.md"; t 'the plan file is gone' no
reset; mkdir -p "$repo/backend" && git -C "$repo/backend" init -q
  t 'a nested repo never set up for the vault (D51)' no "" \
    "{\"cwd\":\"$repo/backend\",\"tool_input\":{\"file_path\":\"$plans/quiet-river.md\"}}"

echo "== mirrored into today's day folder =="
reset; t 'a written plan' yes
  grep -q PLAN-V1 "$copy" 2>/dev/null || { fails=$((fails+1)); echo "FAIL <- the copy holds the plan"; }
  printf '%s\n' "$last_out" | grep -q '"additionalContext"' || { fails=$((fails+1)); echo "FAIL <- tells the agent"; }
reset; t 'first write' yes; echo 'PLAN-V2' > "$plans/quiet-river.md"; t 'a rewrite replaces the copy' yes
  grep -q PLAN-V2 "$copy" 2>/dev/null || { fails=$((fails+1)); echo "FAIL <- the copy is the latest plan"; }
reset "~/vault"; t 'vault named in the ~/ form' yes

echo "== a session started in a sub-project: its own day folder (D38) =="
reset; mkdir -p "$repo/apps/web/.agents"; copy="$vault/Agent/Scratch/$(date +%F)/apps/web/plan quiet-river.md"
  CLAUDE_PROJECT_DIR="$repo/apps/web" t 'copied under apps/web/' yes

echo
[ "$fails" -eq 0 ] && echo "all plan-mirror cases pass" || { echo "$fails case(s) FAILED"; exit 1; }
