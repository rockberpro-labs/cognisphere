#!/usr/bin/env bash
# Self-check for the session-start SessionStart hook:  bash hooks/session-start.test.sh
#
# Runs every case inside a throwaway repo and vault under $TMPDIR. Exits non-zero if any
# case regresses.
set -uo pipefail

H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-start.sh"
bash -n "$H" || exit 1
[ -x "$H" ] || { echo "missing exec bit: session-start.sh (git update-index --chmod=+x)"; exit 1; }
perl -MJSON::PP -e1 || { echo "perl with JSON::PP is required (the hook needs it too)"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export TMPDIR="$tmp" HOME="$tmp"   # `~/` expands here

repo="$tmp/repo"; vault="$tmp/vault"
# A fresh repo and a vault with Home, Open Threads, two Log notes and a Scratch README.
# $1 is the path form AGENTS.local.md names.
reset() {
  rm -rf "$repo" "$vault"
  mkdir -p "$repo" "$vault/Agent/Log" "$vault/Agent/State" "$vault/Agent/Scratch"
  git -C "$repo" init -q -b feat
  printf '# local\n\n## Agent workspace\n\n- The vault for this project is `%s` (outside the repo).\n' \
    "${1:-$vault}" > "$repo/AGENTS.local.md"
  echo 'HOME-NOTE' > "$vault/Agent/00 Home.md"
  echo 'THREADS-NOTE' > "$vault/Agent/State/Open Threads.md"
  echo 'OLD-LOG' > "$vault/Agent/Log/2026-01-01.md"
  echo 'NEW-LOG' > "$vault/Agent/Log/2026-02-01.md"
  echo 'r' > "$vault/Agent/Scratch/README.md"
}

fails=0
# t <name> <grep -E pattern the output must match, or '^$' for none> [payload override]
t() {
  local p="${3:-$(printf '{"session_id":"s","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$repo")}"
  local out; out="$(printf '%s' "$p" | bash "$H" 2>&1)"; local r=$? s=ok
  if [ "$r" != 0 ]; then s=FAIL
  elif [ "$2" = '^$' ]; then [ -z "$out" ] || s=FAIL
  else printf '%s\n' "$out" | grep -Eq "$2" || s=FAIL; fi
  [ "$s" = ok ] || { fails=$((fails+1)); printf '%s\n' "$out" | sed 's/^/       /'; }
  printf '%-4s exit=%s  <- %s\n' "$s" "$r" "$1"
}

echo "== quiet: no vault, or not a vault project =="
reset; rm "$repo/AGENTS.local.md"; t 'no AGENTS.local.md' '^$'
reset /nope/missing; t 'the configured vault has no Home' '^$'
reset; t 'not a git repo' '^$' "{\"cwd\":\"$tmp\"}"
reset; t 'payload is not JSON' '^$' 'not json'

echo "== injects the reading order =="
reset; t 'Home' 'HOME-NOTE'
reset; t 'Open Threads' 'THREADS-NOTE'
reset; t 'the latest Log note' 'NEW-LOG'
reset; out="$(printf '{"cwd":"%s"}' "$repo" | bash "$H")"
  if printf '%s\n' "$out" | grep -q OLD-LOG; then fails=$((fails+1)); echo "FAIL <- an older Log note"; else echo "ok   <- not an older Log note"; fi
reset "~/vault"; t 'vault named in the ~/ form' 'HOME-NOTE'
reset; rm "$vault"/Agent/Log/*; t 'no Log note yet' 'THREADS-NOTE'
reset; seq 1 400 >> "$vault/Agent/State/Open Threads.md"; t 'a long note is capped' 'more lines: read the note'

echo "== Scratch/ leftovers =="
reset; echo p > "$vault/Agent/Scratch/2026-02-01 plan.md"; t 'a leftover is listed' '2026-02-01 plan\.md'
reset; out="$(printf '{"cwd":"%s"}' "$repo" | bash "$H")"
  if printf '%s\n' "$out" | grep -q 'left from an earlier'; then fails=$((fails+1)); echo "FAIL <- README alone is no leftover"; else echo "ok   <- README alone is no leftover"; fi

echo
[ "$fails" -eq 0 ] && echo "all session-start cases pass" || { echo "$fails case(s) FAILED"; exit 1; }
