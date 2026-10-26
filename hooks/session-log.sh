#!/usr/bin/env bash
# Stop hook: session-log. Before the agent stops, checks that a session which changed
# something left its entry in the vault's Log (Session Protocol § End, D34).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`").
#   Blocks the stop with exit 2, the reason going to the agent, when since the session
#   began (its first transcript timestamp) the repo gained a commit or a changed file, or
#   a vault State/ note changed, and no file in the vault's Log/ changed.
#
#   Also blocks, in the same reply, when the session changed 3 or more repo files
#   (committed or not) and nothing in the vault's Scratch/ changed: the working notes
#   AGENTS.local.md asks for before a multi-step edit were never written (D35). Anything
#   written under Scratch/ counts, a day folder's note or a file since deleted (D36).
#
# Soft, because a stop is often a pause waiting on the user, not the end: the agent may
# just stop again (`stop_hook_active` lets that through), and the same changes are never
# reported twice: after a block, only changes newer than it count.
# Limit: a missed Findings entry changes no file, so nothing here can see it.
#
# Fails OPEN: any internal error exits 0 so the session is never wedged.
set -uo pipefail

payload="$(cat)" || exit 0
# stop_hook_active, session_id, cwd and the session's start (epoch seconds, from the first
# `timestamp` in the transcript), NUL-separated. perl + JSON::PP, as in guard.sh.
{ IFS= read -r -d '' active && IFS= read -r -d '' sid && IFS= read -r -d '' cwd \
    && IFS= read -r -d '' start; } < <(printf '%s' "$payload" | perl -MJSON::PP -MTime::Local -0777 -ne '
  my $j = eval { decode_json($_) }; exit 0 unless ref $j eq "HASH";
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
  my $sid = $j->{session_id} // ""; $sid =~ s/[^A-Za-z0-9_-]//g;
  print join("\0", $j->{stop_hook_active} ? 1 : 0, $sid, $j->{cwd} // "", $start), "\0";
' 2>/dev/null) || exit 0
[ "$active" = 1 ] && exit 0
[ -n "$start" ] || exit 0
[ -n "$cwd" ] && { cd "$cwd" 2>/dev/null || exit 0; }
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# The vault path is whatever the local configuration says, never derived here.
vault="$(sed -n 's/^- The vault for this project is `\([^`]*\)`.*/\1/p' "$root/AGENTS.local.md" 2>/dev/null | head -n 1)"
[ -n "$vault" ] || exit 0
case "$vault" in '~/'*) vault="$HOME/${vault#'~/'}" ;; esac
[ -d "$vault/Agent/Log" ] || exit 0

# After a block, only what changed since then counts: the marker's mtime is that time.
marker=
if [ -n "$sid" ]; then
  marker="${TMPDIR:-/tmp}/cognisphere-session-log-$sid"
  if [ -e "$marker" ]; then
    m="$(perl -e 'print +(stat $ARGV[0])[9] // ""' "$marker" 2>/dev/null)"
    [ -n "$m" ] && [ "$m" -gt "$start" ] && since="$m"
  fi
fi
logged_since="$start"; since="${since:-$start}"

# newer <epoch> [path...]: prints each path (a file, or the files under a directory)
# modified after <epoch>. Paths also come NUL-separated on stdin when none are given.
newer() {
  perl -MFile::Find -0 -e '
    my $t = shift; my @p = @ARGV ? @ARGV : grep { length } map { chomp; $_ } <STDIN>;
    for my $p (@p) {
      if (-d $p) { find({ no_chdir => 1, wanted => sub { print "$_\n" if -f && (stat _)[9] > $t } }, $p) }
      elsif (-f $p && (stat _)[9] > $t) { print "$p\n" }
    }' "$@" 2>/dev/null
}

# touched <epoch> <dir>: prints the dir, or anything under it, modified after <epoch>.
# Unlike newer, folders count, so a file created and then deleted is still seen.
touched() {
  perl -MFile::Find -e '
    my $t = shift;
    find({ no_chdir => 1, wanted => sub { print "$_\n" if (lstat $_)[9] > $t } }, @ARGV);' "$@" 2>/dev/null
}

log_done=; [ -n "$(newer "$logged_since" "$vault/Agent/Log")" ] && log_done=1
scratch_done=1
[ -d "$vault/Agent/Scratch" ] && [ -z "$(touched "$start" "$vault/Agent/Scratch")" ] && scratch_done=
[ -n "$log_done" ] && [ -n "$scratch_done" ] && exit 0

commits="$(git -C "$root" log --since="@$since" --format='%h %s' 2>/dev/null)"
files="$(cd "$root" && { git diff -z --name-only HEAD 2>/dev/null; git ls-files -z --others --exclude-standard 2>/dev/null; } | newer "$since")"
state="$(newer "$since" "$vault/Agent/State")"

need_log=; [ -z "$log_done" ] && [ -n "$commits$files$state" ] && need_log=1
need_scratch=
if [ -z "$scratch_done" ] && [ -n "$commits$files" ]; then
  # Every repo file the session touched, committed or not, counted once.
  touched_files="$(cd "$root" && { git log -z --since="@$start" --name-only --format= 2>/dev/null
    git diff -z --name-only HEAD 2>/dev/null; git ls-files -z --others --exclude-standard 2>/dev/null; } \
    | newer "$start" | sort -u | grep -c .)"
  [ "${touched_files:-0}" -ge 3 ] && need_scratch=1
fi
[ -n "$need_log$need_scratch" ] || exit 0

[ -n "$marker" ] && touch "$marker" 2>/dev/null

list() { printf "%s\n" "$1" | sed -n "1,5s/^/    /p"; local n; n=$(( $(printf "%s\n" "$1" | wc -l) - 5 )); [ "$n" -gt 0 ] && echo "    … and $n more"; }
{
  if [ -n "$need_log" ]; then
    echo "session-log: this session changed things and the vault's Log has no entry for it yet."
    echo
    [ -n "$commits" ] && { echo "  commits:"; list "$commits"; }
    [ -n "$files" ] && { echo "  files:"; list "$files"; }
    [ -n "$state" ] && { echo "  vault State/ notes:"; list "${state//"$vault/Agent/"/}"; }
    echo
    echo "If this reply ends the work, do Session Protocol § End now: append \`## Session N\`"
    echo "to $vault/Agent/Log/$(date +%F).md and update State/Open Threads.md."
  fi
  if [ -n "$need_scratch" ]; then
    [ -n "$need_log" ] && echo
    echo "session-log: this session touched $touched_files repo files and wrote nothing in $vault/Agent/Scratch/."
    echo "Write \`Scratch/$(date +%F)/<topic>.md\` now: the plan, the files touched, what you ruled"
    echo "out and what is still open. If this reply ends the work, promote what matters to the"
    echo "Log, Open Threads or Findings; the day folder stays, as the history of the work."
  fi
  echo "If you are pausing for the user mid-task, just stop again: this reminder comes back"
  echo "only when something else changes."
} >&2
exit 2
