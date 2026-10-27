#!/usr/bin/env bash
# Stop hook: session-log. Before the agent stops, checks that a session which changed
# something left its entry in the vault's Log (Session Protocol § End, D34).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`").
#   Blocks the stop with exit 2, the reason going to the agent, when since the session
#   began (its first transcript timestamp) the repo gained a commit or a changed file, or
#   a vault State/ note changed, and no file in the vault's Log/ changed. A Log written
#   this session counts only for the work before it: once 3 or more repo files (committed
#   or not) changed after its newest write, it is behind and the stop blocks again (D43).
#
#   Also blocks, in the same reply, when the session changed 3 or more repo files
#   (committed or not) and nothing in the vault's Scratch/ changed: the working notes
#   AGENTS.local.md asks for before a multi-step edit were never written (D35). Anything
#   written under Scratch/ counts, a day folder's note or a file since deleted (D36). As
#   with the Log, a note falls behind once 3 or more repo files changed after the newest
#   Scratch write (D43).
#
#   And when, with a Scratch/ folder, the session wrote into Claude Code's own stores by
#   a route scratch-redirect doesn't see (Bash): a file in this session's scratchpad
#   (claude*/…/<session id>/scratchpad/ in the temp dir) or in the project's auto-memory
#   folder, modified this session. The agent is asked to move it into the vault (D43).
#
# Soft, because a stop is often a pause waiting on the user, not the end: the agent may
# just stop again (`stop_hook_active` lets that through), and the same changes are never
# reported twice: after a block, only changes newer than it count.
#
#   A session started in a sub-project (D38, vault-of.sh): only its own Scratch/<day>/<tag>/
#   folders count, and a Log entry written without the sub-project's tag (#frontend) gets
#   one reminder to add it.
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

# The nearest AGENTS.local.md, from the repo up, names the vault (vault-of.sh).
. "$(dirname "$0")/vault-of.sh"
vault="$(vault_of "$root")"
[ -n "$vault" ] || exit 0
[ -d "$vault/Agent/Log" ] || exit 0
subproject_of "${CLAUDE_PROJECT_DIR:-$PWD}"

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

# last_write <files|all> <epoch> <path>...: the newest mtime after <epoch> under the
# paths, of files only or, with all, of folders too, so a file created and then deleted
# still counts. Empty when none.
last_write() {
  perl -MFile::Find -e '
    my $all = shift eq "all"; my $t = shift; my $m = 0;
    find({ no_chdir => 1, wanted => sub { return unless $all || -f;
      my $x = (lstat $_)[9]; $m = $x if $x > $t && $x > $m } }, grep { -e } @ARGV);
    print $m if $m;' "$@" 2>/dev/null
}
# max <a> <b>: the larger epoch.
max() { [ "$1" -gt "$2" ] && echo "$1" || echo "$2"; }

log_at="$(last_write files "$logged_since" "$vault/Agent/Log")"
scratch_at=
if [ -d "$vault/Agent/Scratch" ]; then
  if [ -n "$tag" ]; then
    # Only this sub-project's folders, Scratch/<day>/<tag>/ for any day.
    scratch_at="$(last_write all "$start" "$vault/Agent/Scratch"/*/"$tag")"
  else
    scratch_at="$(last_write all "$start" "$vault/Agent/Scratch")"
  fi
fi
# A Log written since the last reminder without the sub-project's tag.
need_tag=
if [ -n "$tag" ] && [ -n "$log_at" ]; then
  logs="$(newer "$since" "$vault/Agent/Log")"
  [ -n "$logs" ] && ! printf '%s\n' "$logs" | perl -e '
    my $t = shift; while (my $f = <STDIN>) { chomp $f; open my $h, "<", $f or next;
      local $/; exit 0 if <$h> =~ /(?<![\w&\/])#\Q$t\E(?![\w\/-])/ } exit 1' "$tag" 2>/dev/null \
    && need_tag=1
fi

commits="$(git -C "$root" log --since="@$since" --format='%h %s' 2>/dev/null)"
files="$(cd "$root" && { git diff -z --name-only HEAD 2>/dev/null; git ls-files -z --others --exclude-standard 2>/dev/null; } | newer "$since")"
state="$(newer "$since" "$vault/Agent/State")"
# behind <epoch>: every repo file the session touched, committed or not, changed after
# <epoch>, counted once.
behind() {
  (cd "$root" && { git log -z --since="@$start" --name-only --format= 2>/dev/null
    git diff -z --name-only HEAD 2>/dev/null; git ls-files -z --others --exclude-standard 2>/dev/null; } \
    | newer "$1" | sort -u)
}

need_log= log_behind=
if [ -z "$log_at" ]; then
  [ -n "$commits$files$state" ] && need_log=1
else
  log_behind="$(behind "$(max "$log_at" "$since")")"
  [ "$(printf '%s' "$log_behind" | grep -c .)" -ge 3 ] && need_log=1
fi
need_scratch= scratch_behind=
if [ -d "$vault/Agent/Scratch" ]; then
  if [ -z "$scratch_at" ]; then
    if [ -n "$commits$files" ]; then
      touched_files="$(behind "$start" | grep -c .)"
      [ "${touched_files:-0}" -ge 3 ] && need_scratch=1
    fi
  else
    scratch_behind="$(behind "$(max "$scratch_at" "$since")")"
    [ "$(printf '%s' "$scratch_behind" | grep -c .)" -ge 3 ] && need_scratch=1
  fi
fi

# Claude Code's own stores, written this session by a route scratch-redirect doesn't see.
strays=
if [ -d "$vault/Agent/Scratch" ]; then
  config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  strays="$({
    if [ -n "$sid" ]; then
      for t in "${TMPDIR:-/tmp}" /tmp; do
        for d in "$t"/claude*/*/"$sid"/scratchpad "$t"/claude*/"$sid"/scratchpad; do
          [ -d "$d" ] && newer "$since" "$d"
        done
      done
    fi
    # Auto-memory: Claude Code names the folder after the project path with every
    # non-alphanumeric turned into `-` (git root or cwd, so both), as in session-start.
    for p in "$root" "$cwd"; do
      [ -n "$p" ] || continue
      d="$config/projects/$(perl -e '($s = shift) =~ s/[^A-Za-z0-9]/-/g; print $s' "$p")/memory"
      [ -d "$d" ] && newer "$since" "$d"
    done
  } | sort -u)"
fi
[ -n "$need_log$need_scratch$need_tag$strays" ] || exit 0

[ -n "$marker" ] && touch "$marker" 2>/dev/null

list() { printf "%s\n" "$1" | sed -n "1,5s/^/    /p"; local n; n=$(( $(printf "%s\n" "$1" | wc -l) - 5 )); [ "$n" -gt 0 ] && echo "    … and $n more"; }
{
  if [ -n "$need_log" ] && [ -z "$log_at" ]; then
    echo "session-log: this session changed things and the vault's Log has no entry for it yet."
    echo
    [ -n "$commits" ] && { echo "  commits:"; list "$commits"; }
    [ -n "$files" ] && { echo "  files:"; list "$files"; }
    [ -n "$state" ] && { echo "  vault State/ notes:"; list "${state//"$vault/Agent/"/}"; }
    echo
    echo "If this reply ends the work, do Session Protocol § End now: append \`## Session N\`"
    echo "to $vault/Agent/Log/$(date +%F).md and update State/Open Threads.md."
    [ -n "$tag" ] && echo "This session started in the sub-project $tag/: tag the entry #$tag."
  elif [ -n "$need_log" ]; then
    echo "session-log: $(printf '%s\n' "$log_behind" | grep -c .) repo files changed since this session last wrote the vault's Log:"
    list "$log_behind"
    echo
    echo "If this reply ends the work, bring this session's entry in"
    echo "$vault/Agent/Log/$(date +%F).md up to date (Session Protocol § End: what was done,"
    echo "decided and left open) and update State/Open Threads.md."
    [ -n "$tag" ] && echo "This session started in the sub-project $tag/: tag the entry #$tag."
  fi
  if [ -n "$need_tag" ]; then
    [ -n "$need_log" ] && echo
    echo "session-log: this session started in the sub-project $tag/, and its Log entry has no #$tag."
    echo "Add #$tag to the entry, and to the Open Threads and Findings items it added, so a"
    echo "session started in $tag/ finds them (Session Protocol § During)."
  fi
  if [ -n "$need_scratch" ]; then
    [ -n "$need_log$need_tag" ] && echo
    if [ -z "$scratch_at" ]; then
      echo "session-log: this session touched $touched_files repo files and wrote nothing in $vault/Agent/Scratch/${tag:+*/$tag/}."
      echo "Write \`Scratch/$(date +%F)/${tag:+$tag/}<topic>.md\` now: the plan, the files touched, what you ruled"
      echo "out and what is still open."
    else
      echo "session-log: $(printf '%s\n' "$scratch_behind" | grep -c .) repo files changed since this session last wrote in $vault/Agent/Scratch/${tag:+*/$tag/}:"
      list "$scratch_behind"
      echo "Bring the note up to date: what's done, what changed in the plan, what's still open."
    fi
    echo "If this reply ends the work, promote what matters to the Log, Open Threads or"
    echo "Findings; the day folder stays, as the history of the work."
  fi
  if [ -n "$strays" ]; then
    [ -n "$need_log$need_tag$need_scratch" ] && echo
    echo "session-log: this session wrote into Claude Code's own stores, which this project's vault replaces:"
    list "$strays"
    echo "Move each into the vault: a note, script or result worth keeping to"
    echo "$vault/Agent/Scratch/$(date +%F)/${tag:+$tag/}; an auto-memory entry to the vault note it belongs to"
    echo "(State/Preferences.md for the maintainer and how to work, the area's .agents/memory/"
    echo "note for the code), then delete it, MEMORY.md last. Throwaway material goes in a"
    echo "\`mktemp -d\` folder instead."
  fi
  echo "If you are pausing for the user mid-task, just stop again: this reminder comes back"
  echo "only when something else changes."
} >&2
exit 2
