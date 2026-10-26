#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit and NotebookEdit: scratch-first. Blocks an
# edit of a repo file until the session has written a note in the vault's Scratch/: the
# plan AGENTS.local.md asks for before the first edit of a task (D35).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`")
#   that has a Scratch/ folder. Edits outside the repo (the vault itself included) pass.
#   A note counts when a file in Scratch/ other than README.md was modified after the
#   session began (its first transcript timestamp). Once one exists, every edit passes.
#
# Hard, unlike session-log: it keeps blocking until the note exists, since a note is
# one Write away. Limit: an edit made through Bash (sed -i, a heredoc) isn't seen.
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
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# Only repo files: a relative path is the cwd's, as the tools resolve it.
case "$path" in /*) ;; *) path="$PWD/$path" ;; esac
case "$path" in "$root"/*) ;; *) exit 0 ;; esac

# The vault path is whatever the local configuration says, never derived here.
vault="$(sed -n 's/^- The vault for this project is `\([^`]*\)`.*/\1/p' "$root/AGENTS.local.md" 2>/dev/null | head -n 1)"
[ -n "$vault" ] || exit 0
case "$vault" in '~/'*) vault="$HOME/${vault#'~/'}" ;; esac
scratch="$vault/Agent/Scratch"
[ -d "$scratch" ] || exit 0

note="$(perl -MFile::Find -e '
  my $t = shift;
  find({ no_chdir => 1, wanted => sub {
    print "$_\n" if -f && !m{/README\.md$} && (stat _)[9] > $t } }, @ARGV);' "$start" "$scratch" 2>/dev/null | head -n 1)"
[ -n "$note" ] && exit 0

{
  echo "scratch-first: no working note in $scratch/ yet this session."
  echo "Before the first edit, write \`$scratch/$(date +%F) <topic>.md\`: the plan, the files"
  echo "you'll touch and the open questions (a line or two is enough for a small fix)."
  echo "Then retry this edit. Keep the note current as you go; at the end, promote what"
  echo "matters and delete it."
} >&2
exit 2
