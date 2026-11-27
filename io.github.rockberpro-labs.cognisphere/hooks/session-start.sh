#!/usr/bin/env bash
# SessionStart hook: session-start. Puts the vault's reading order into the session's
# context, so the agent starts from it instead of having to remember to open it (D35).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`").
#   Prints, for the agent: Agent/00 Home.md, State/Preferences.md (what auto-memory
#   would otherwise load), State/Open Threads.md, the latest note in Log/ (its tail, where
#   the newest session is), the files in today's Scratch/ day folder (the work in
#   flight), any file loose in Scratch/ outside a day folder, the newest earlier day
#   folder, as history, and any file left in Claude Code's auto-memory for the project,
#   to move into the vault (D36). Each note is capped so a grown note can't flood the
#   context. It ends by telling the agent to keep its working state in
#   Scratch/, not in Claude Code's session scratchpad, plans or auto-memory.
#
#   A session started in a sub-project (D38, vault-of.sh) gets only the open threads
#   tagged with it or with no sub-project's tag, told how many it left out, and today's
#   Scratch notes but those of other sub-projects' folders; it is told its tag and its
#   Scratch/<day>/<tag>/ folder.
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

# The nearest AGENTS.local.md, from the repo up, names the vault (vault-of.sh).
. "$(dirname "$0")/vault-of.sh"
vault="$(vault_of "$root")"
[ -n "$vault" ] || exit 0
a="$vault/Agent"
[ -f "$a/00 Home.md" ] || exit 0
subproject_of "${CLAUDE_PROJECT_DIR:-$PWD}"

# note <title> <file> <head|tail> <lines> [the path to show, when <file> is a copy]
note() {
  [ -f "$2" ] || return 0
  local n; n=$(wc -l < "$2")
  echo; echo "=== $1 (${5:-$2}) ==="
  "$3" -n "$4" "$2"
  [ "$n" -gt "$4" ] && echo "[… $((n - $4)) more lines: read the note for the rest]"
  return 0
}

# owner <path>: the sub-project a Scratch/ path, relative to its day folder, belongs to:
# its longest leading folder that is one (has an .agents/ under home). Empty when none.
owner() {
  local d="$1"
  while [ "$d" != "${d%/*}" ]; do
    d="${d%/*}"; [ -d "$home/$d/.agents" ] && { printf '%s' "$d"; return 0; }
  done
}

# threads <file>: Open Threads without the numbered items ("N. …" and the lines that
# continue it) tagged only with other sub-projects, then a last line with how many it
# left out. A tag naming no sub-project's folder (#bug) doesn't count.
threads() {
  perl -e '
    my ($tag, $home) = @ARGV; my (@item, @blank); my $left = 0;
    # Tagged with sub-projects, none of them this one.
    sub other { my $n = 0; for (/(?<![\w&\/])#([A-Za-z0-9_\/-]*[A-Za-z_\/-][A-Za-z0-9_\/-]*)/g) {
        (my $t = $_) =~ s{/+$}{}; return 0 if $t eq $tag; $n++ if -d "$home/$t/.agents" } $n }
    sub flush { if (@item) { local $_ = join "", @item; if (other()) { $left++ } else { print } }
      print @blank; @item = (); @blank = () }
    while (<STDIN>) {
      if (/^\d+\.\s/) { flush(); push @item, $_; next }
      if (@item) {
        if (/^\s*$/) { push @blank, $_; next }
        # Indented, or straight after the item with no blank line: still the item.
        if (/^\s+\S/ || (!@blank && !/^(#|<!--)/)) { push @item, @blank, $_; @blank = (); next }
        flush();
      }
      print;
    }
    flush(); print "$left\n";' "$tag" "$home" < "$1"
}

today="$(date +%F)"
latest="$(ls "$a/Log/" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | tail -n 1)"
current="$(cd "$a/Scratch/$today" 2>/dev/null && find . -type f 2>/dev/null | sed 's|^\./||' | sort)"
loose="$(cd "$a/Scratch" 2>/dev/null && find . -maxdepth 1 -type f ! -name README.md 2>/dev/null | sed 's|^\./||' | sort)"
earlier="$(ls "$a/Scratch/" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | grep -vx "$today" | sort | tail -n 1)"
# Auto-memory written before the vault took it over: Claude Code names the folder after
# the project path with every non-alphanumeric turned into `-` (git root or cwd, so both).
# ponytail: a path long enough for Claude Code to shorten with a hash isn't found.
config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mem="$(for p in "$root" "$cwd"; do [ -n "$p" ] && perl -e '($s = shift) =~ s/[^A-Za-z0-9]/-/g; print "$s\n"' "$p"; done \
  | sort -u | while IFS= read -r s; do d="$config/projects/$s/memory"
    [ -d "$d" ] && find "$d" -maxdepth 1 -type f 2>/dev/null; done | sort)"

# A sub-project's session: other sub-projects' threads and Scratch notes left out.
threads_note="$a/State/Open Threads.md" left=0 hidden=0 work="$a/Scratch/$today/"
if [ -n "$tag" ]; then
  work="$a/Scratch/$today/$tag/"
  if [ -f "$threads_note" ]; then
    tmp="$(mktemp)" || exit 0; trap 'rm -f "$tmp"' EXIT
    threads "$threads_note" > "$tmp" || exit 0
    left="$(tail -n 1 "$tmp")"; perl -i -ne 'print unless eof' "$tmp"; threads_note="$tmp"
  fi
  if [ -n "$current" ]; then
    mine="$(printf '%s\n' "$current" | while IFS= read -r f; do
      o="$(owner "$f")"; [ -z "$o" ] || [ "$o" = "$tag" ] && printf '%s\n' "$f"; done)"
    hidden=$(( $(printf '%s\n' "$current" | grep -c .) - $(printf '%s' "$mine" | grep -c .) ))
    current="$mine"
  fi
fi

{
  echo "session-start: the vault for this project is $vault. Its reading order, loaded for you:"
  note "00 Home" "$a/00 Home.md" head 60
  note "Preferences" "$a/State/Preferences.md" head 80
  note "Open Threads" "$threads_note" head 150 "$a/State/Open Threads.md"
  [ "$left" -gt 0 ] && echo "[$left thread(s) tagged with other sub-projects left out: read the note for them]"
  [ -n "$latest" ] && note "latest Log" "$a/Log/$latest" tail 80
  if [ -n "$current" ]; then
    echo; echo "=== Scratch/$today/: today's working notes, the work in flight ==="
    printf '%s\n' "$current" | sed -n '1,10s/^/  /p'
  fi
  [ "$hidden" -gt 0 ] && echo "[$hidden more in Scratch/$today/, in other sub-projects' folders]"
  if [ -n "$loose" ]; then
    echo; echo "=== Scratch/ files outside a day folder: move each into its Scratch/YYYY-MM-DD/ ==="
    printf '%s\n' "$loose" | sed -n '1,10s/^/  /p'
  fi
  [ -n "$earlier" ] && { echo; echo "Older Scratch/ day folders are history, not current (newest: Scratch/$earlier/): read one only when the task needs it."; }
  if [ -n "$mem" ]; then
    echo; echo "=== Claude Code auto-memory for this project, outside the vault: move it in ==="
    printf '%s\n' "$mem" | sed -n '1,10s/^/  /p'
    echo "Move each entry into the vault note it belongs to (about the maintainer or how to work"
    echo "-> State/Preferences.md; about the code -> the area's .agents/memory/ note, or tell the"
    echo "maintainer), then delete the file, MEMORY.md last, and say so in today's Log."
  fi
  if [ -n "$tag" ]; then
    echo; echo "This session started in the sub-project $tag/: tag #$tag what it adds to the Log,"
    echo "Open Threads and Findings (Session Protocol § During)."
  fi
  echo
  echo "Run \`git status\` and \`git log -5\` next. Write your working notes in $work"
  echo "as AGENTS.local.md says. This project's working state lives in the vault: use that"
  echo "folder instead of Claude Code's session scratchpad, plans folder or auto-memory."
}
exit 0
