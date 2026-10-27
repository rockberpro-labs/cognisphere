#!/usr/bin/env bash
# Self-check for the scratch-redirect PreToolUse hook:  bash hooks/scratch-redirect.test.sh
#
# Runs every case inside a throwaway repo, vault, config dir and temp dir under $TMPDIR.
# Exits non-zero if any case regresses.
set -uo pipefail

H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scratch-redirect.sh"
bash -n "$H" || exit 1
[ -x "$H" ] || { echo "missing exec bit: scratch-redirect.sh (git update-index --chmod=+x)"; exit 1; }
perl -MJSON::PP -e1 || { echo "perl with JSON::PP is required (the hook needs it too)"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export TMPDIR="$tmp" HOME="$tmp"   # `~/` and ~/.claude expand here
unset CLAUDE_CONFIG_DIR CLAUDE_PROJECT_DIR

repo="$tmp/repo"; vault="$tmp/vault"
pad="$tmp/claude/-home-u-repo/0b6f-session/scratchpad"
mem="$tmp/.claude/projects/-home-u-repo/memory"
# A fresh repo and a vault with a Scratch/ folder. $1 is the path form AGENTS.local.md names.
reset() {
  rm -rf "$repo" "$vault"
  mkdir -p "$repo/src" "$vault/Agent/Scratch"
  git -C "$repo" init -q -b feat
  printf '# local\n\n## Agent workspace\n\n- The vault for this project is `%s` (outside the repo).\n' \
    "${1:-$vault}" > "$repo/AGENTS.local.md"
}

fails=0
t(){ # t <name> <expected exit> <file_path> [tool] [payload override]
  local p="${5:-$(printf '{"session_id":"s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"file_path":"%s"}}' \
    "$repo" "${4:-Write}" "$3")}"
  local out; out="$(printf '%s' "$p" | bash "$H" 2>&1)"
  local r=$?; local s=ok
  [ "$r" = "$2" ] || { s=FAIL; fails=$((fails+1)); printf '%s\n' "$out" | sed 's/^/       /'; }
  printf '%-4s got=%s want=%s  <- %s\n' "$s" "$r" "$2" "$1"
  last_out="$out"
}

echo "== quiet: not a vault project, or not one of Claude Code's stores =="
reset; rm "$repo/AGENTS.local.md"; t 'no AGENTS.local.md' 0 "$pad/notes.md"
reset /nope/missing; t 'the configured vault has no Scratch/' 0 "$pad/notes.md"
reset; t 'not a git repo' 0 "$pad/x" Write "{\"cwd\":\"$tmp\",\"tool_input\":{\"file_path\":\"$pad/x\"}}"
reset; t 'payload is not JSON' 0 "" Write 'not json'
reset; t 'a repo file' 0 "$repo/src/a.txt" Edit
reset; t 'a relative path' 0 "src/a.txt"
reset; t 'a vault note' 0 "$vault/Agent/Scratch/2026-01-01/plan.md"
reset; t 'a plan-mode plan file' 0 "$tmp/.claude/plans/quiet-river.md"
reset; t 'another file in the temp dir' 0 "$tmp/build/out.txt"
reset; t 'a mktemp -d folder, for throwaway material' 0 "$tmp/tmp.Ab12Cd/repo/fixture.json"
reset; t 'a scratchpad folder outside the temp dir' 0 "/srv/claude-x/scratchpad/a.md"

echo "== blocks: the session scratchpad =="
reset; t 'Write in the scratchpad' 2 "$pad/notes.md"
  printf '%s\n' "$last_out" | grep -q "Scratch/$(date +%F)/notes.md" || { fails=$((fails+1)); echo "FAIL <- names the day-folder path"; }
  printf '%s\n' "$last_out" | grep -q 'mktemp -d' || { fails=$((fails+1)); echo "FAIL <- says where throwaway material goes"; }
reset; t 'Edit in a scratchpad subfolder' 2 "$pad/sub/run.sh" Edit
reset; t 'a /tmp/claude-<uid> scratchpad' 2 "/tmp/claude-1000/-home-u-repo/0b6f/scratchpad/a.md"
reset; t 'a Windows Temp scratchpad' 2 "/c/Users/u/AppData/Local/Temp/claude/C--repo/0b6f/scratchpad/a.md"
reset "~/vault"; t 'vault named in the ~/ form' 2 "$pad/notes.md"

echo "== blocks: auto-memory =="
reset; t 'Write in auto-memory' 2 "$mem/feedback.md"
  printf '%s\n' "$last_out" | grep -q 'Open Threads' || { fails=$((fails+1)); echo "FAIL <- says where it goes instead"; }
  printf '%s\n' "$last_out" | grep -q 'State/Preferences.md' || { fails=$((fails+1)); echo "FAIL <- names Preferences for what auto-memory keeps about the maintainer"; }
reset; t 'Edit of MEMORY.md' 2 "$mem/MEMORY.md" Edit
reset; CLAUDE_CONFIG_DIR="$tmp/cfg" t 'under CLAUDE_CONFIG_DIR' 2 "$tmp/cfg/projects/x/memory/a.md"

echo "== a session started in a sub-project: its own day folder (D38) =="
reset; mkdir -p "$repo/frontend/.agents"
  CLAUDE_PROJECT_DIR="$repo/frontend" t 'Write in the scratchpad' 2 "$pad/notes.md"
  printf '%s\n' "$last_out" | grep -q "Scratch/$(date +%F)/frontend/notes.md" || { fails=$((fails+1)); echo "FAIL <- names its tag's folder"; }

echo
[ "$fails" -eq 0 ] && echo "all scratch-redirect cases pass" || { echo "$fails case(s) FAILED"; exit 1; }
