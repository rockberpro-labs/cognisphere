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
#   And when a reply says something lies outside the task and what is wrong with it
#   ("unrelated, but the retry loop never backs off") and State/Findings.md wasn't
#   written since: the entry D27 asks for the moment it's noticed. It reads that from the
#   transcript, and hands over the item's heading, numbered after the note's, and its
#   Seen line with today and HEAD (D45).
#
#   The Log entry it hands over (D44) also has Not verified filled in from the
#   transcript's last test run, a Bash command that looks like one or the test-runner
#   agent: none ran, it failed, or repo files changed after it (D45).
#
#   A session started in a sub-project (D38, vault-of.sh): only its own Scratch/<day>/<tag>/
#   folders count, and a Log entry written without the sub-project's tag (#frontend) gets
#   one reminder to add it.
# Limits: both readings of the transcript are heuristics. A test command no pattern knows
# reads as "no tests ran", and a finding mentioned in other words is missed.
#
# Fails OPEN: any internal error exits 0 so the session is never wedged.
set -uo pipefail

payload="$(cat)" || exit 0
# stop_hook_active, session_id, cwd, the session's start (epoch seconds, from the first
# `timestamp` in the transcript) and the transcript's path, NUL-separated. perl +
# JSON::PP, as in guard.sh.
{ IFS= read -r -d '' active && IFS= read -r -d '' sid && IFS= read -r -d '' cwd \
    && IFS= read -r -d '' start && IFS= read -r -d '' transcript; } < <(printf '%s' "$payload" | perl -MJSON::PP -MTime::Local -0777 -ne '
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
  print join("\0", $j->{stop_hook_active} ? 1 : 0, $sid, $j->{cwd} // "", $start,
    $j->{transcript_path} // ""), "\0";
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

# The transcript, read once (D45). Prints the session's last test run, "T\t<epoch>\t<ok|
# fail|bg|ran>\t<command>": a Bash command that looks like a test run (quoted strings
# aside), or the test-runner agent, whose outcome is in its report. A call a hook or the
# user refused never ran, so it doesn't count. Then each sentence of the agent's replies
# since <since> that says something lies outside the task, "N\t<epoch>\t<sentence>",
# code blocks aside, and not one that names Findings or this hook (a reply to its block).
scan() {
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 0
  perl -MJSON::PP -MTime::Local -e '
    my ($f, $since) = @ARGV; open my $t, "<", $f or exit 0;
    sub epoch { my @d = ($_[0] // "") =~ /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/ or return 0;
      timegm($d[5], $d[4], $d[3], $d[2], $d[1] - 1, $d[0]) }
    my $tests = qr{\b(?:pytest|jest|vitest|mocha|rspec|phpunit|ctest|tox|nox|bats|unittest)\b
      | \b(?:npm|pnpm|yarn|bun)\s+(?:run\s+)?test\b | \b(?:go|cargo|dotnet|mix|swift|deno|zig)\s+test\b
      | \b(?:make|just|task|rake)\s+(?:test|check)\b | \b(?:mvnw?|gradlew?)\b.*\b(?:test|verify|check)\b
      | (?:^|[;&|(\n`]|\b(?:do|then|else|time|exec|xargs)\s)\s*(?:(?:ba|z)?sh\s+|\./)\S*test\S*\.sh\b
      | \bfor\s+\w+\s+in\s+[^;\n]*test\S*\.sh\b}x;
    # An aside says outright that something is wrong, or puts something outside the task
    # and, in the same sentence, says what is wrong with it ("an unrelated commit" is not one).
    my $aside = qr{\b(?:pre-?existing\s+(?:bug|issue|problem|failure|defect)
      | (?:looks|might\s+be|may\s+be|seems)\s+(?:like\s+)?an?\s+(?:latent\s+|separate\s+|real\s+)?bug
      | worth\s+(?:its\s+own|a\s+separate)\s+(?:issue|fix|PR|change))}xi;
    my $outside = qr{\b(?:unrelated|out\s+of\s+scope|outside\s+(?:the|this|my)\s+(?:task|scope|change)
      | not\s+part\s+of\s+(?:the|this)\s+(?:task|change|fix) | side\s+note | in\s+passing
      | (?:also|separately)\s+(?:noticed|spotted) | already\s+(?:there|existed|present|broken)
      | predat\w+ | before\s+(?:this|my|the)\s+(?:change|task|session))}xi;
    my $wrong = qr{\b(?:bug|broken|breaks?|fail\w*|errors?|crash\w*|leak\w*|race|risk\w*|wrong|incorrect
      | missing|stale|dead|unused|never|unchecked|unsafe|insecure|vulnerab\w*|smell\w*|flaky|typo|TODO
      | should|ought)\b|n\x27t\b}xi;
    my (%run, $last);
    while (<$t>) {
      next unless /"(?:tool_use|tool_result|text)"/;
      my $l = eval { decode_json($_) } or next;
      next unless ref $l eq "HASH" && !$l->{isSidechain} && ref $l->{message} eq "HASH";
      my $c = $l->{message}{content}; next unless ref $c eq "ARRAY";
      my $at = epoch($l->{timestamp}) or next;
      for my $b (grep { ref eq "HASH" } @$c) {
        my $type = $b->{type} // "";
        if ($type eq "tool_use" && ref $b->{input} eq "HASH") {
          my $in = $b->{input};
          if (($b->{name} // "") eq "Bash" && defined $in->{command}) {
            # Heredoc bodies and quoted strings are text (a Log entry, a commit message), not commands.
            (my $bare = $in->{command}) =~ s/<<-?\s*(["\x27]?)(\w+)\1[^\n]*\n.*?(?:\n\s*\2[ \t]*(?=\n|\z)|\z)//gs;
            $bare =~ s/"(?:[^"\\]|\\.)*"|\x27[^\x27]*\x27//g;
            next unless $bare =~ $tests;
            # Named by the test command itself, up to the next separator or redirect.
            (my $cmd = substr $bare, $-[0]) =~ s/^[\s;&|(`]*(?:(?:do|then|else|time|exec|xargs)\s+)?//;
            $cmd =~ s/\s*(?:[;&|\n`]|\d*[<>]).*//s;
            $run{$b->{id} // ""} = [$cmd, $in->{run_in_background} ? "bg" : "ok"];
          } elsif (($in->{subagent_type} // "") =~ /test-runner/) {
            $run{$b->{id} // ""} = ["the test-runner agent", "ran"];
          }
        } elsif ($type eq "tool_result" and my $r = delete $run{$b->{tool_use_id} // ""}) {
          my $out = ref $b->{content} eq "ARRAY"
            ? join("\n", map { ref eq "HASH" ? $_->{text} // "" : "" } @{$b->{content}}) : $b->{content} // "";
          if ($b->{is_error}) { next unless $out =~ /^Exit code \d+/; $r->[1] = "fail" }
          $last = [$at, $r->[1], $r->[0]];
        } elsif ($type eq "text" && ($l->{type} // "") eq "assistant" && $at > $since) {
          (my $txt = $b->{text} // "") =~ s/```.*?(?:```|\z)//gs;
          for my $s (split /(?<=[.!?])\s+|\n+/, $txt) {
            $s =~ s/^[\s>*-]+|\s+$//g; $s =~ s/\s+/ /g;
            print "N\t$at\t$s\n" if ($s =~ $aside || $s =~ $outside && $s =~ $wrong)
              && $s !~ /Findings|session-log/i;
          }
        }
      }
    }
    print "T\t$last->[0]\t$last->[1]\t$last->[2]\n" if $last;' "$transcript" "$since" 2>/dev/null
}
scanned="$(scan)"
last_test="$(printf '%s\n' "$scanned" | sed -n 's/^T\t//p')"

# A remark outside the task with nothing added to Findings since (D45): what D27 asks for
# the moment it's noticed, and which, unlike the Log, no file change would show.
findings="$vault/Agent/State/Findings.md" asides=
if [ -f "$findings" ]; then
  f_at="$(perl -e 'print +(stat $ARGV[0])[9] // 0' "$findings" 2>/dev/null)"
  asides="$(printf '%s\n' "$scanned" | perl -ne 'BEGIN { $t = shift }
    print "$2\n" if /^N\t(\d+)\t(.*)/ && $1 > $t && !$seen{$2}++' "${f_at:-0}" 2>/dev/null)"
fi
[ -n "$need_log$need_scratch$need_tag$strays$asides" ] || exit 0

[ -n "$marker" ] && touch "$marker" 2>/dev/null

# skeleton: the Session Protocol § End entry, numbered after today's note and with
# Changed filled in: the session's commits, "uncommitted" for repo changes not committed
# yet, and the vault files git doesn't see (D44). The rest is the agent's to write.
day_log="$vault/Agent/Log/$(date +%F).md"
skeleton() {
  local n shas dirty vfiles changed=
  n="$(grep -c '^## Session ' "$day_log" 2>/dev/null)"; n=$(( ${n:-0} + 1 ))
  shas="$(git -C "$root" log --reverse --since="@$start" --format=%h 2>/dev/null | paste -sd, - | sed 's/,/, /g')"
  dirty="$(cd "$root" && { git diff -z --name-only HEAD 2>/dev/null; git ls-files -z --others --exclude-standard 2>/dev/null; } | newer "$start")"
  vfiles="$(newer "$start" "$vault/Agent/State" "$vault/Agent/Scratch" | sed "s|^$vault/Agent/||" | sort)"
  [ -n "$shas" ] && changed="$shas"
  [ -n "$dirty" ] && changed="${changed:+$changed; }uncommitted"
  if [ -n "$vfiles" ]; then
    local more=$(( $(printf '%s\n' "$vfiles" | wc -l) - 5 ))
    changed="${changed:+$changed; }vault: $(printf '%s\n' "$vfiles" | sed -n '1,5p' | paste -sd, - | sed 's/,/, /g')"
    [ "$more" -gt 0 ] && changed="$changed and $more more"
  fi
  echo "## Session $n${tag:+ #$tag}"
  printf -- '- **%s:**\n' Asked Found Did
  echo "- **Changed:** $changed"
  local nv; nv="$(unverified)"
  echo "- **Not verified:**${nv:+ $nv}"
  echo "- **Next:**"
}

# unverified: Not verified as the entry would say it, from the transcript's last test run
# against the repo files the session touched (D45). Empty when that run passed after
# the last change, or the session touched no repo file.
unverified() {
  local touched at st cmd label when after n
  touched="$(behind "$start")"; [ -n "$touched" ] || return 0
  [ -n "$last_test" ] || { echo "no tests ran this session"; return 0; }
  IFS=$'\t' read -r at st cmd <<< "$last_test"
  [ "${#cmd}" -gt 60 ] && cmd="${cmd:0:59}…"
  if [ "$st" = ran ]; then label="$cmd"; else label="\`$cmd\`"; fi
  when="$(perl -MPOSIX=strftime -e 'print strftime("%H:%M", localtime shift)' "$at" 2>/dev/null)"
  after="$(printf '%s\n' "$touched" | tr '\n' '\0' | (cd "$root" && newer "$at"))"
  if [ -n "$after" ]; then
    n=$(( $(printf '%s\n' "$after" | wc -l) - 3 ))
    echo "$(printf '%s\n' "$after" | sed -n '1,3s/.*/`&`/p' | paste -sd, - | sed 's/,/, /g')$([ "$n" -gt 0 ] && echo " and $n more files") changed after the last test run ($label, $when)"
  elif [ "$st" = fail ]; then
    echo "the last test run ($label, $when) failed"
  elif [ "$st" = bg ]; then
    echo "the last test run ($label, $when) ran in the background, its result not checked"
  fi
}

list() { printf "%s\n" "$1" | sed -n "1,5s/^/    /p"; local n; n=$(( $(printf "%s\n" "$1" | wc -l) - 5 )); [ "$n" -gt 0 ] && echo "    … and $n more"; }
{
  if [ -n "$need_log" ] && [ -z "$log_at" ]; then
    echo "session-log: this session changed things and the vault's Log has no entry for it yet."
    echo
    [ -n "$commits" ] && { echo "  commits:"; list "$commits"; }
    [ -n "$files" ] && { echo "  files:"; list "$files"; }
    [ -n "$state" ] && { echo "  vault State/ notes:"; list "${state//"$vault/Agent/"/}"; }
    echo
    echo "If this reply ends the work, do Session Protocol § End now: append this entry to"
    echo "$day_log, filling in the blanks (Changed comes from git and the vault, Not"
    echo "verified from the session's test runs: check them), and update State/Open Threads.md."
    [ -f "$day_log" ] || echo "The note is new: start it with the frontmatter and Back line of an earlier Log note."
    echo
    skeleton | sed 's/^/    /'
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
  if [ -n "$asides" ]; then
    [ -n "$need_log$need_tag$need_scratch$strays" ] && echo
    echo "session-log: this session's replies point at something outside the task, and nothing"
    echo "was written in State/Findings.md since:"
    printf '%s\n' "$asides" | perl -CS -ne 'chomp;
      $_ = substr($_, 0, 159) . "\x{2026}" if length > 160; print "    \x{201C}$_\x{201D}\n" if $. <= 3;
      END { print "    \x{2026} and ", $. - 3, " more\n" if $. > 3 }' 2>/dev/null
    echo "If one is a finding (a bug, a risk, a missing test, an improvement), add it to"
    echo "$findings under Open now, after checking it isn't there"
    echo "already (Session Protocol § During), starting from:"
    echo
    # The next number after any item's, open or closed; the commit it was seen at.
    n="$(perl -ne '$m = $1 if /^#+\s*(?:~~)?\s*(\d+)\./ && $1 > $m; END { print $m + 1 }' "$findings" 2>/dev/null)"
    echo "    ### ${n:-1}. [bug|risk|smell|test|improvement|idea] what: \`path:line\`${tag:+ #$tag}"
    echo "    Seen $(date +%F) at \`$(git -C "$root" rev-parse --short HEAD 2>/dev/null)\`, while <the task>."
    echo "    <the evidence and a suggestion>"
    echo "    Status: open"
    echo
    echo "If it belongs to the task, or is already recorded elsewhere, leave Findings as it is."
  fi
  echo
  echo "If you are pausing for the user mid-task, just stop again: this reminder comes back"
  echo "only when something else changes."
} >&2
exit 2
