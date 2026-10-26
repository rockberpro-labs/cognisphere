#!/usr/bin/env bash
# Self-check for the scratch-first PreToolUse hook:  bash hooks/scratch-first.test.sh
#
# Runs every case inside a throwaway repo and vault under $TMPDIR, with file times set
# around a fake session start. Exits non-zero if any case regresses.
set -uo pipefail

H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scratch-first.sh"
bash -n "$H" || exit 1
[ -x "$H" ] || { echo "missing exec bit: scratch-first.sh (git update-index --chmod=+x)"; exit 1; }
perl -MJSON::PP -e1 || { echo "perl with JSON::PP is required (the hook needs it too)"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export TMPDIR="$tmp" HOME="$tmp"   # `~/` expands here

now="$(date +%s)"; start=$((now - 3600))
iso() { perl -e 'my @t = gmtime shift; printf "%04d-%02d-%02dT%02d:%02d:%02d.000Z", $t[5]+1900, $t[4]+1, @t[3,2,1,0]' "$1"; }
at() { perl -e 'my $t = shift; utime $t, $t, @ARGV or exit 1' "$@"; }   # at <epoch> <file>...
printf '{"type":"mode"}\n{"type":"user","timestamp":"%s"}\n' "$(iso "$start")" > "$tmp/transcript.jsonl"

repo="$tmp/repo"; vault="$tmp/vault"; day="$vault/Agent/Scratch/$(date +%F)"
# A fresh repo and a vault whose Scratch/ holds only a README from yesterday.
# $1 is the path form AGENTS.local.md names.
reset() {
  rm -rf "$repo" "$vault"
  mkdir -p "$repo/src" "$vault/Agent/Scratch"
  git -C "$repo" init -q -b feat
  printf '# local\n\n## Agent workspace\n\n- The vault for this project is `%s` (outside the repo).\n' \
    "${1:-$vault}" > "$repo/AGENTS.local.md"
  echo r > "$vault/Agent/Scratch/README.md"
  at "$((start - 86400))" "$vault/Agent/Scratch/README.md" "$repo/AGENTS.local.md"
}
# note <epoch>: a note in today's day folder, written at <epoch>.
note() { mkdir -p "$day"; echo p > "$day/plan.md"; at "$1" "$day/plan.md"; }
# edits <epoch> <n>: <n> repo files written at <epoch>.
edits() { local i; for i in $(seq 1 "$2"); do echo x > "$repo/src/f$i.txt"; at "$1" "$repo/src/f$i.txt"; done; }

fails=0
t(){ # t <name> <expected exit> [file_path] [tool] [payload override]
  local key=file_path; [ "${4:-Edit}" = NotebookEdit ] && key=notebook_path
  local p="${5:-$(printf '{"session_id":"s","transcript_path":"%s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"%s":"%s"}}' \
    "$tmp/transcript.jsonl" "$repo" "${4:-Edit}" "$key" "${3:-$repo/src/a.txt}")}"
  local out; out="$(printf '%s' "$p" | bash "$H" 2>&1)"
  local r=$?; local s=ok
  [ "$r" = "$2" ] || { s=FAIL; fails=$((fails+1)); printf '%s\n' "$out" | sed 's/^/       /'; }
  printf '%-4s got=%s want=%s  <- %s\n' "$s" "$r" "$2" "$1"
  last_out="$out"
}

echo "== quiet: not a vault project, or not a repo file =="
reset; rm "$repo/AGENTS.local.md"; t 'no AGENTS.local.md' 0
reset /nope/missing; t 'the configured vault has no Scratch/' 0
reset; t 'a file outside the repo' 0 "$tmp/elsewhere.txt"
reset; t 'a note in the vault itself' 0 "$vault/Agent/Log/today.md"
reset; t 'not a git repo' 0 "$tmp/x" Edit \
  "{\"transcript_path\":\"$tmp/transcript.jsonl\",\"cwd\":\"$tmp\",\"tool_input\":{\"file_path\":\"$tmp/x\"}}"
reset; t 'no transcript: start unknown' 0 "" Edit "{\"cwd\":\"$repo\",\"tool_input\":{\"file_path\":\"$repo/a\"}}"
reset; t 'payload is not JSON' 0 "" Edit 'not json'

echo "== blocks: a repo edit before any Scratch note this session =="
reset; t 'Edit, Scratch has only its README' 2
reset; t 'Write of a new file' 2 "$repo/src/new.txt" Write
reset; t 'NotebookEdit' 2 "$repo/src/n.ipynb" NotebookEdit
reset; t 'a relative path' 2 "src/a.txt"
reset "~/vault"; t 'vault named in the ~/ form' 2
reset; note "$((start - 60))"; t 'a note left from an earlier session' 2
reset; echo p > "$vault/Agent/Scratch/plan.md"; t 'a loose note, outside a day folder' 2
reset; echo r >> "$vault/Agent/Scratch/README.md"; t 'only the README changed' 2
reset; t 'the block names the day folder' 2
  printf '%s\n' "$last_out" | grep -q "Scratch/$(date +%F)/" || { fails=$((fails+1)); echo "FAIL <- the block names Scratch/$(date +%F)/"; }

echo "== passes: a note written this session, in a day folder =="
reset; note "$((start + 60))"; t "a note in today's day folder" 0
reset; mkdir -p "$vault/Agent/Scratch/2020-01-01/sub"; echo p > "$vault/Agent/Scratch/2020-01-01/sub/plan.md"
  t 'a note in another day folder, written this session (past midnight)' 0

echo "== the note falls behind: 3+ repo files changed since the newest Scratch write =="
reset; note "$((start + 60))"; edits "$((start + 120))" 2; t '2 files since the note' 0
reset; note "$((start + 60))"; edits "$((start + 120))" 3; t '3 files since the note' 2
  printf '%s\n' "$last_out" | grep -q 'f1\.txt' || { fails=$((fails+1)); echo "FAIL <- the block names the files"; }
reset; note "$((start + 180))"; edits "$((start + 120))" 3; t '3 files, the note updated after them' 0
reset; note "$((start + 60))"; edits "$((start + 120))" 3
  git -C "$repo" add src && git -C "$repo" -c user.name=t -c user.email=t@t commit -qm x
  t '3 files since the note, committed' 2
reset; edits "$((start - 120))" 3; note "$((start + 60))"; t '3 files changed before the session' 0

echo
[ "$fails" -eq 0 ] && echo "all scratch-first cases pass" || { echo "$fails case(s) FAILED"; exit 1; }
