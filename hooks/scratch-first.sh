#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit and NotebookEdit: scratch-first. Blocks an
# edit of a repo file until the session has written a note in the vault's Scratch/: the
# plan AGENTS.local.md asks for before the first edit of a task (D35), and blocks again
# when the note has fallen behind the work (D36).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`")
#   that has a Scratch/ folder. Edits outside the repo (the vault itself included) pass.
#   A note counts when a file in a day folder, Scratch/YYYY-MM-DD/, was modified after
#   the session began (its first transcript timestamp); a loose file in Scratch/ doesn't.
#   Once one exists, edits pass until 3 or more repo files (committed or not) have
#   changed since the newest Scratch write: then the note must be brought up to date.
#
# Hard, unlike session-log: it keeps blocking until the note is written, since a note
# is one Write away. Limit: an edit made through Bash (sed -i, a heredoc) isn't seen.
#
# Fails OPEN: any internal error exits 0 so the session is never wedged.
set -uo pipefail

payload="$(cat)" || exit 0
# cwd, the edited path and the session's start (epoch seconds, from the first
# `timestamp` in the transcript), NUL-separated. perl + JSON::PP, as in guard.sh.
{ IFS= read -r -d '' cwd && IFS= read -r -d '' path && IFS= read -r -d '' start; } < <(
  printf '%s' "$payload" | perl -MJSON::PP -MTime::Local -0777 -ne '
  my $j = eval { decode_json($_) }; exit 0 unless ref $j eq "HASH";
  my $in = ref $j->{tool_input} eq "HASH" ? $j->{tool_input} : {};
  my $start = "";
  if (defined $j->{transcript_path} && open my $t, "<", $j->{transcript_path}) {
    local $/ = "\n";   # -0777 slurps the payload; the transcript is read by line
    while (<$t>) {
      my $l = eval { decode_json($_) } or next;
      my $ts = ref $l eq "HASH" && $l->{timestamp} or next;
      my @d = $ts =~ /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/ or last;
      $start = timegm($d[5], $d[4], $d[3], $d[2], $d[1] - 1, $d[0]); last;
    }
  }
  print join("\0", $j->{cwd} // "", $in->{file_path} // $in->{notebook_path} // "", $start), "\0";
' 2>/dev/null) || exit 0
[ -n "$path" ] && [ -n "$start" ] || exit 0
[ -n "$cwd" ] && { cd "$cwd" 2>/dev/null || exit 0; }

# Git Bash on Windows mixes C:\, C:/ and /c/ forms; cygpath gives one. Elsewhere, as is.
unix() { if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi; }
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
root="$(unix "$root")"; path="$(unix "$path")"

# Only repo files: a relative path is the cwd's, as the tools resolve it.
case "$path" in /*) ;; *) path="$(unix "$PWD")/$path" ;; esac
case "$path" in "$root"/*) ;; *) exit 0 ;; esac

# The vault path is whatever the local configuration says, never derived here.
vault="$(sed -n 's/^- The vault for this project is `\([^`]*\)`.*/\1/p' "$root/AGENTS.local.md" 2>/dev/null | head -n 1)"
[ -n "$vault" ] || exit 0
case "$vault" in '~/'*) vault="$HOME/${vault#'~/'}" ;; esac
scratch="$(unix "$vault")/Agent/Scratch"
[ -d "$scratch" ] || exit 0
today="$(date +%F)"

# The newest file written this session in a day folder: "<mtime>\t<path>", or nothing.
last="$(perl -MFile::Find -e '
  my ($t, $s) = @ARGV; my ($m, $p) = (0, "");
  find({ no_chdir => 1, wanted => sub {
    return unless -f && m{^\Q$s\E/\d{4}-\d\d-\d\d/};
    my $x = (stat _)[9]; ($m, $p) = ($x, $_) if $x > $t && $x > $m } }, $s);
  print "$m\t$p\n" if $p;' "$start" "$scratch" 2>/dev/null)"

if [ -z "$last" ]; then
  {
    echo "scratch-first: no working note in $scratch/ yet this session."
    echo "Before the first edit, write \`$scratch/$today/<topic>.md\`: the plan, the files"
    echo "you'll touch and the open questions (a line or two is enough for a small fix)."
    echo "Then retry this edit. Keep the note current as you go; at the end, promote what"
    echo "matters to the Log, Open Threads or Findings. The day folder stays: it's the history."
  } >&2
  exit 2
fi

# Repo files the session touched, committed or not, changed after that newest note.
since="${last%%$'\t'*}"; note="${last#*$'\t'}"
behind="$(cd "$root" && { git log -z --since="@$start" --name-only --format= 2>/dev/null
  git diff -z --name-only HEAD 2>/dev/null; git ls-files -z --others --exclude-standard 2>/dev/null; } \
  | perl -0 -e 'my $t = shift; my %s;
      while (<STDIN>) { chomp; next if !length || $s{$_}++; print "$_\n" if -f && (stat _)[9] > $t }' "$since" 2>/dev/null)"
n="$(printf '%s' "$behind" | grep -c .)"
[ "${n:-0}" -ge 3 ] || exit 0

{
  echo "scratch-first: $n repo files changed since you last wrote in Scratch/ (${note#"$scratch/"}):"
  printf '%s\n' "$behind" | sed -n '1,5s/^/    /p'
  echo "Bring the note up to date (what's done, what changed in the plan, what's still"
  echo "open), or start \`$scratch/$today/<topic>.md\` for a new task. Then retry this edit."
} >&2
exit 2
