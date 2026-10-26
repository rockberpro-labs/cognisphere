#!/usr/bin/env bash
# SessionStart hook: session-start. Puts the vault's reading order into the session's
# context, so the agent starts from it instead of having to remember to open it (D35).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`").
#   Prints, for the agent: Agent/00 Home.md, State/Preferences.md (what auto-memory
#   would otherwise load), State/Open Threads.md, the latest note in Log/ (its tail, where
#   the newest session is), the files in today's Scratch/ day folder (the work in
#   flight), any file loose in Scratch/ outside a day folder, and the newest earlier day
#   folder, as history (D36). Each note is capped so a grown note
#   can't flood the context. It ends by telling the agent to keep its working state in
#   Scratch/, not in Claude Code's session scratchpad, plans or auto-memory.
#
# Fails OPEN: any internal error exits 0 with no output, so the session starts as usual.
set -uo pipefail

payload="$(cat)" || exit 0
# cwd, from the payload. perl + JSON::PP, as in guard.sh.
cwd="$(printf '%s' "$payload" | perl -MJSON::PP -0777 -ne '
  my $j = eval { decode_json($_) }; print $j->{cwd} // "" if ref $j eq "HASH";
' 2>/dev/null)" || exit 0
[ -n "$cwd" ] && { cd "$cwd" 2>/dev/null || exit 0; }
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# The vault path is whatever the local configuration says, never derived here.
vault="$(sed -n 's/^- The vault for this project is `\([^`]*\)`.*/\1/p' "$root/AGENTS.local.md" 2>/dev/null | head -n 1)"
[ -n "$vault" ] || exit 0
case "$vault" in '~/'*) vault="$HOME/${vault#'~/'}" ;; esac
a="$vault/Agent"
[ -f "$a/00 Home.md" ] || exit 0

# note <title> <file> <head|tail> <lines>
note() {
  [ -f "$2" ] || return 0
  local n; n=$(wc -l < "$2")
  echo; echo "=== $1 ($2) ==="
  "$3" -n "$4" "$2"
  [ "$n" -gt "$4" ] && echo "[… $((n - $4)) more lines: read the note for the rest]"
  return 0
}

today="$(date +%F)"
latest="$(ls "$a/Log/" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | tail -n 1)"
current="$(cd "$a/Scratch/$today" 2>/dev/null && find . -type f 2>/dev/null | sed 's|^\./||' | sort)"
loose="$(cd "$a/Scratch" 2>/dev/null && find . -maxdepth 1 -type f ! -name README.md 2>/dev/null | sed 's|^\./||' | sort)"
earlier="$(ls "$a/Scratch/" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | grep -vx "$today" | sort | tail -n 1)"

{
  echo "session-start: the vault for this project is $vault. Its reading order, loaded for you:"
  note "00 Home" "$a/00 Home.md" head 60
  note "Preferences" "$a/State/Preferences.md" head 80
  note "Open Threads" "$a/State/Open Threads.md" head 150
  [ -n "$latest" ] && note "latest Log" "$a/Log/$latest" tail 80
  if [ -n "$current" ]; then
    echo; echo "=== Scratch/$today/: today's working notes, the work in flight ==="
    printf '%s\n' "$current" | sed -n '1,10s/^/  /p'
  fi
  if [ -n "$loose" ]; then
    echo; echo "=== Scratch/ files outside a day folder: move each into its Scratch/YYYY-MM-DD/ ==="
    printf '%s\n' "$loose" | sed -n '1,10s/^/  /p'
  fi
  [ -n "$earlier" ] && { echo; echo "Older Scratch/ day folders are history, not current (newest: Scratch/$earlier/): read one only when the task needs it."; }
  echo
  echo "Run \`git status\` and \`git log -5\` next. Write your working notes in $a/Scratch/$today/"
  echo "as AGENTS.local.md says. This project's working state lives in the vault: use that"
  echo "folder instead of Claude Code's session scratchpad, plans folder or auto-memory."
}
exit 0
