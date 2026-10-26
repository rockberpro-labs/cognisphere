#!/usr/bin/env bash
# SessionStart hook: session-start. Puts the vault's reading order into the session's
# context, so the agent starts from it instead of having to remember to open it (D35).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`").
#   Prints, for the agent: Agent/00 Home.md, State/Open Threads.md, the latest note in
#   Log/ (its tail, where the newest session is), and the files left in Scratch/ by a
#   session that never pruned them. Each note is capped so a grown note can't flood
#   the context.
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

latest="$(ls "$a/Log/" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | tail -n 1)"
scratch="$(ls "$a/Scratch/" 2>/dev/null | grep -vx 'README.md')"

{
  echo "session-start: the vault for this project is $vault. Its reading order, loaded for you:"
  note "00 Home" "$a/00 Home.md" head 60
  note "Open Threads" "$a/State/Open Threads.md" head 150
  [ -n "$latest" ] && note "latest Log" "$a/Log/$latest" tail 80
  if [ -n "$scratch" ]; then
    echo; echo "=== Scratch/ left from an earlier session: promote what matters, then delete ==="
    printf '%s\n' "$scratch" | sed -n '1,10s/^/  /p'
  fi
  echo
  echo "Run \`git status\` and \`git log -5\` next. Write your working notes in $a/Scratch/ as AGENTS.local.md says."
}
exit 0
