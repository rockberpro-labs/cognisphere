#!/usr/bin/env bash
# Self-check for the session-log Stop hook:  bash hooks/session-log.test.sh
#
# Runs every case inside a throwaway repo and vault under $TMPDIR, with file times set
# around a fake session start. Exits non-zero if any case regresses.
set -uo pipefail

H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-log.sh"
bash -n "$H" || exit 1
[ -x "$H" ] || { echo "missing exec bit: session-log.sh (git update-index --chmod=+x)"; exit 1; }
perl -MJSON::PP -e1 || { echo "perl with JSON::PP is required (the hook needs it too)"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export TMPDIR="$tmp" HOME="$tmp"   # the hook's marker lands here; `~/` expands here
unset CLAUDE_PROJECT_DIR

now="$(date +%s)"; start=$((now - 3600))
iso() { perl -e 'my @t = gmtime shift; printf "%04d-%02d-%02dT%02d:%02d:%02d.000Z", $t[5]+1900, $t[4]+1, @t[3,2,1,0]' "$1"; }
at() { perl -e 'my $t = shift; utime $t, $t, @ARGV or exit 1' "$@"; }   # at <epoch> <file>...
tx="$tmp/transcript.jsonl"
# say <epoch> <text> [user]: a reply (or, with user, a prompt) in the transcript.
say() { perl -MJSON::PP -e 'my ($t, $s, $who) = @ARGV; print encode_json({ type => $who || "assistant",
  timestamp => $t, message => { role => $who || "assistant", content => [{ type => "text", text => $s }] } }), "\n"' \
  "$(iso "$1")" "$2" "${3:-}" >> "$tx"; }
# ran <epoch> <ok|fail|refused|bg|agent> <command>: a Bash call (or a test-runner agent)
# and its result.
ran() { perl -MJSON::PP -e 'my ($t, $st, $cmd) = @ARGV; my $id = "tu" . int(rand 1e9);
  my $use = $st eq "agent" ? { type => "tool_use", id => $id, name => "Agent", input => { subagent_type => "cognisphere:test-runner" } }
    : { type => "tool_use", id => $id, name => "Bash", input => { command => $cmd, $st eq "bg" ? (run_in_background => JSON::PP::true) : () } };
  my $res = { type => "tool_result", tool_use_id => $id,
    content => $st eq "fail" ? "Exit code 1\nnot ok" : $st eq "refused" ? "PreToolUse:Bash hook error: BLOCKED" : "ok" };
  $res->{is_error} = JSON::PP::true if $st eq "fail" || $st eq "refused";
  print encode_json({ type => "assistant", timestamp => $t, message => { content => [$use] } }), "\n",
    encode_json({ type => "user", timestamp => $t, message => { content => [$res] } }), "\n"' "$(iso "$1")" "$2" "${3:-}" >> "$tx"; }

repo="$tmp/repo"; vault="$tmp/vault"; sid=0
# A fresh repo whose only commit and files predate the session, and a vault with a Log,
# a State note and a Scratch/ README from yesterday. $1 is the path form AGENTS.local.md names.
reset() {
  rm -rf "$repo" "$vault" "$tmp"/cognisphere-session-log-* "$tmp"/claude-* "$tmp/.claude"
  printf '{"type":"mode"}\n{"type":"user","timestamp":"%s"}\n' "$(iso "$start")" > "$tx"
  mkdir -p "$repo" "$vault/Agent/Log" "$vault/Agent/State" "$vault/Agent/Scratch"
  git -C "$repo" init -q -b feat
  echo a > "$repo/a.txt"; echo '/AGENTS.local.md' > "$repo/.gitignore"
  git -C "$repo" add a.txt .gitignore
  GIT_COMMITTER_DATE="@$((start - 86400))" git -C "$repo" -c user.email=t@t -c user.name=t \
    commit -q --date="@$((start - 86400))" -m init
  printf '# local\n\n## Agent workspace\n\n- The vault for this project is `%s` (outside the repo).\n' \
    "${1:-$vault}" > "$repo/AGENTS.local.md"
  echo x > "$vault/Agent/Log/yesterday.md"; echo y > "$vault/Agent/State/Open Threads.md"
  echo r > "$vault/Agent/Scratch/README.md"
  at "$((start - 86400))" "$repo/a.txt" "$repo/AGENTS.local.md" "$repo/.gitignore" \
    "$vault/Agent/Log/yesterday.md" "$vault/Agent/State/Open Threads.md" \
    "$vault/Agent/Scratch/README.md" "$vault/Agent/Scratch"
  sid=$((sid + 1))
}

fails=0
t(){ # t <name> <expected exit> [stop_hook_active] [payload override]
  local p="${4:-$(printf '{"session_id":"s%s","transcript_path":"%s","cwd":"%s","hook_event_name":"Stop","stop_hook_active":%s}' \
    "$sid" "$tmp/transcript.jsonl" "$repo" "${3:-false}")}"
  out="$(printf '%s' "$p" | bash "$H" 2>&1)"
  local r=$?; local s=ok
  [ "$r" = "$2" ] || { s=FAIL; fails=$((fails+1)); printf '%s\n' "$out" | sed 's/^/       /'; }
  printf '%-4s got=%s want=%s  <- %s\n' "$s" "$r" "$2" "$1"
}

echo "== quiet: nothing to log, or no vault =="
reset; t 'nothing changed since the session began' 0
reset; echo b >> "$repo/a.txt"; at "$((start - 60))" "$repo/a.txt"; t 'a change from before the session' 0
reset; rm "$repo/AGENTS.local.md"; echo b >> "$repo/a.txt"; t 'no AGENTS.local.md: not a vault project' 0
reset /nope/missing; echo b >> "$repo/a.txt"; t 'the configured vault has no Log/' 0
reset; echo b >> "$repo/a.txt"; t 'not a git repo' 0 false \
  "{\"session_id\":\"x\",\"transcript_path\":\"$tmp/transcript.jsonl\",\"cwd\":\"$tmp\"}"
reset; echo b >> "$repo/a.txt"; t 'no transcript: start unknown' 0 false "{\"cwd\":\"$repo\"}"
reset; echo b >> "$repo/a.txt"; t 'payload is not JSON' 0 false 'not json'

echo "== blocks: the session changed something and the Log has nothing =="
reset; echo b >> "$repo/a.txt"; t 'tracked file modified' 2
reset; echo n > "$repo/new.txt"; t 'untracked file added' 2
reset; echo z >> "$vault/Agent/State/Open Threads.md"; t 'a vault State/ note changed' 2
reset; git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m s; t 'a commit, clean tree' 2
reset "~/vault"; echo b >> "$repo/a.txt"; t 'vault named in the ~/ form' 2

echo "== soft: logged, a second stop, the same changes again =="
reset; echo b >> "$repo/a.txt"; echo s > "$vault/Agent/Log/today.md"; t 'Log written this session' 0
reset; echo b >> "$repo/a.txt"; t 'stop_hook_active: the agent stopped again' 0 true
reset; echo b >> "$repo/a.txt"; at "$((now - 10))" "$repo/a.txt"; t 'first stop after a change' 2
t 'next stop, nothing new since the block' 0
echo c >> "$repo/a.txt"; at "$((now + 10))" "$repo/a.txt"; t 'next stop, a newer change' 2

echo "== scratch: 3+ repo files touched and nothing written in Scratch/ =="
three() { echo b >> "$repo/a.txt"; echo n > "$repo/n1.txt"; echo n > "$repo/n2.txt"; }
logged() { echo s > "$vault/Agent/Log/today.md"; }
reset; three; logged; t '3 files, logged, Scratch untouched' 2
reset; echo b >> "$repo/a.txt"; echo n > "$repo/n1.txt"; logged; t '2 files: under the threshold' 0
reset; three; logged; mkdir -p "$vault/Agent/Scratch/d"; echo p > "$vault/Agent/Scratch/d/plan.md"; t 'a Scratch note written' 0
reset; three; logged; mkdir -p "$vault/Agent/Scratch/d"; echo p > "$vault/Agent/Scratch/d/plan.md"; rm -r "$vault/Agent/Scratch/d"
  t 'a Scratch note written, then pruned' 0
reset; three; git -C "$repo" add -A; git -C "$repo" -c user.email=t@t -c user.name=t commit -q -m s
  logged; t '3 files committed, clean tree' 2
reset; three; logged; rm -r "$vault/Agent/Scratch"; t 'the vault has no Scratch/' 0
reset; three; t 'no Log and no Scratch: one block for both' 2
reset; three; logged; t 'stop_hook_active: the agent stopped again' 0 true
reset; three; logged; at "$((now - 10))" "$repo/a.txt" "$repo/n1.txt" "$repo/n2.txt"; t 'first stop' 2
t 'next stop, nothing new since the block' 0

echo "== behind: 3+ repo files changed after the newest Log or Scratch write (D43) =="
# early <dir> <file>: a vault note written early in the session, at start + 60.
early() { mkdir -p "$1"; echo e > "$1/$2"; at "$((start + 60))" "$1/$2"; }
late() { three; at "$((start + 120))" "$repo/a.txt" "$repo/n1.txt" "$repo/n2.txt"; }
scr() { early "$vault/Agent/Scratch/d" plan.md; at "$((start + 60))" "$vault/Agent/Scratch/d" "$vault/Agent/Scratch"; }
reset; scr; early "$vault/Agent/Log" today.md; late; t 'Log written early, 3 files after it' 2
reset; scr; early "$vault/Agent/Log" today.md; echo b >> "$repo/a.txt"; echo n > "$repo/n1.txt"
  at "$((start + 120))" "$repo/a.txt" "$repo/n1.txt"; t 'Log written early, 2 files after it' 0
reset; scr; late; at "$((start + 180))" "$vault/Agent/Scratch/d/plan.md"; logged; t 'Log written after the 3 files' 0
reset; scr; early "$vault/Agent/Log" today.md; late
  echo z >> "$vault/Agent/State/Open Threads.md"; t 'Log early, State updated after: still behind' 2
reset; scr; late; logged; t 'Scratch written early, 3 files after it' 2
reset; late; scr; at "$((start + 180))" "$vault/Agent/Scratch/d/plan.md"; logged; t 'Scratch written after the 3 files' 0
reset; scr; early "$vault/Agent/Log" today.md; late; at "$((now - 10))" "$repo/a.txt" "$repo/n1.txt" "$repo/n2.txt"
  t 'behind: first stop' 2
  t 'behind: next stop, nothing new since the block' 0

echo "== strays: Claude Code's own stores written this session (D43) =="
pad="$tmp/claude-1/-repo"
reset; mkdir -p "$pad/s$sid/scratchpad"; echo x > "$pad/s$sid/scratchpad/x.md"; t "this session's scratchpad" 2
  printf '%s\n' "$out" | grep -q 'scratchpad/x.md' || { fails=$((fails+1)); echo "FAIL <- names the file"; }
reset; mkdir -p "$pad/other/scratchpad"; echo x > "$pad/other/scratchpad/x.md"; t "another session's scratchpad" 0
reset; mkdir -p "$pad/s$sid/scratchpad"; echo x > "$pad/s$sid/scratchpad/x.md"
  at "$((start - 60))" "$pad/s$sid/scratchpad/x.md"; t 'a scratchpad file from before the session' 0
mem="$tmp/.claude/projects/$(printf '%s' "$repo" | perl -pe 's/[^A-Za-z0-9]/-/g')/memory"
reset; mkdir -p "$mem"; echo m > "$mem/MEMORY.md"; t 'auto-memory written this session' 2
reset; mkdir -p "$mem"; echo m > "$mem/MEMORY.md"; at "$((start - 60))" "$mem/MEMORY.md"; t 'auto-memory from before the session' 0
reset; mkdir -p "$mem"; echo m > "$mem/MEMORY.md"; rm -r "$vault/Agent/Scratch"; t 'auto-memory, the vault has no Scratch/' 0
reset; mkdir -p "$mem"; echo m > "$mem/MEMORY.md"; at "$((now - 10))" "$mem/MEMORY.md"; t 'strays: first stop' 2
  t 'strays: next stop, nothing new since the block' 0

echo "== the entry to paste: numbered, with Changed filled in (D44) =="
has() { printf '%s\n' "$out" | grep -qF -- "$1" || { fails=$((fails+1)); echo "FAIL <- the message has: $1"; }; }
lacks() { printf '%s\n' "$out" | grep -qF -- "$1" && { fails=$((fails+1)); echo "FAIL <- the message lacks: $1"; }; }
today_log="$vault/Agent/Log/$(date +%F).md"
reset; echo b >> "$repo/a.txt"; t 'no note today: Session 1' 2
  has '    ## Session 1'; has '- **Asked:**'; has '- **Next:**'; has '- **Changed:** uncommitted'
  has 'The note is new'
reset; printf '## Session 1\nx\n## Session 2\ny\n' > "$today_log"; at "$((start - 60))" "$today_log"
  echo b >> "$repo/a.txt"; t "two sessions in today's note: Session 3" 2
  has '## Session 3'; lacks 'The note is new'
reset; git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m s
  sha="$(git -C "$repo" log -1 --format=%h)"; t 'a commit, clean tree: its sha' 2
  has "- **Changed:** $sha"; lacks 'uncommitted'
reset; echo b >> "$repo/a.txt"; echo z >> "$vault/Agent/State/Open Threads.md"; scr
  t 'uncommitted, and vault files git does not see' 2
  has '- **Changed:** uncommitted; vault: Scratch/d/plan.md, State/Open Threads.md'

echo "== Not verified, from the transcript's last test run (D45) =="
T='bash hooks/x.test.sh'
nv() { has "- **Not verified:** $1"; }
reset; echo b >> "$repo/a.txt"; t 'edits, no test ran' 2; nv 'no tests ran this session'
reset; echo b >> "$repo/a.txt"; at "$((start + 60))" "$repo/a.txt"; ran "$((start + 120))" ok "$T"
  t 'a test passed after the last change' 2; has $'- **Not verified:**\n'
reset; echo b >> "$repo/a.txt"; at "$((start + 120))" "$repo/a.txt"; ran "$((start + 60))" ok "$T"
  t 'a file changed after the last test run' 2; nv "\`a.txt\` changed after the last test run (\`$T\`, "
reset; three; at "$((start + 120))" "$repo/a.txt" "$repo/n1.txt" "$repo/n2.txt"; echo n > "$repo/n3.txt"
  at "$((start + 120))" "$repo/n3.txt"; ran "$((start + 60))" ok "$T"; logged; rm -f "$vault/Agent/Log/today.md"
  t 'four files after it: three named' 2; has ' and 1 more files changed after'
reset; echo b >> "$repo/a.txt"; at "$((start + 60))" "$repo/a.txt"; ran "$((start + 90))" ok "$T"; ran "$((start + 120))" fail "$T"
  t 'the last run failed' 2; nv "the last test run (\`$T\`, "; has ') failed'
reset; echo b >> "$repo/a.txt"; at "$((start + 60))" "$repo/a.txt"; ran "$((start + 120))" refused "$T"
  t 'a refused run never ran' 2; nv 'no tests ran this session'
reset; echo b >> "$repo/a.txt"; ran "$((start + 120))" ok 'git commit -m "make pytest pass"'
  t 'a quoted mention is not a run' 2; nv 'no tests ran this session'
reset; echo b >> "$repo/a.txt"; at "$((start + 120))" "$repo/a.txt"; ran "$((start + 60))" ok $'cd /x\nbun test 2>&1 | tail -8'
  t 'a multi-line run: named by its test command' 2; has 'after the last test run (`bun test`, '
reset; echo b >> "$repo/a.txt"; at "$((start + 60))" "$repo/a.txt"; ran "$((start + 120))" bg 'npm test'
  t 'a run in the background' 2; has 'ran in the background, its result not checked'
reset; echo b >> "$repo/a.txt"; at "$((start + 120))" "$repo/a.txt"; ran "$((start + 60))" agent
  t 'the test-runner agent, then a change' 2; has 'after the last test run (the test-runner agent, '
reset; echo z >> "$vault/Agent/State/Open Threads.md"; t 'no repo file touched: left blank' 2
  has $'- **Not verified:**\n'

echo "== Findings: a remark outside the task, nothing added to Findings since (D45) =="
fnd() { printf '# Findings\n\n## Open\n### 2. [bug] x: `a.txt:1`\n\n## Closed\n### ~~4. [idea] y~~\n' > "$vault/Agent/State/Findings.md"
  at "$((start - 86400))" "$vault/Agent/State/Findings.md"; }
A='Done. Unrelated, but the retry loop in pay.ts never backs off.'
reset; fnd; say "$((start + 60))" "$A"; t 'an aside, Findings untouched, nothing else changed' 2
  has '“Unrelated, but the retry loop in pay.ts never backs off.”'; lacks 'Done.'
  has '### 5. [bug|risk|smell|test|improvement|idea] what:'
  has "at \`$(git -C "$repo" rev-parse --short HEAD)\`, while"; lacks 'Log has no entry'
reset; fnd; say "$((start + 60))" "$A"; echo n >> "$vault/Agent/State/Findings.md"; logged; t 'Findings written after it' 0
reset; say "$((start + 60))" "$A"; t 'no Findings.md: an older vault' 0
reset; fnd; say "$((start + 60))" 'That pre-existing bug is now item 5 in Findings.'; t 'an aside that names Findings' 0
reset; fnd; say "$((start + 60))" $'Output:\n```\nunrelated test skipped\n```'; t 'an aside inside a code block' 0
reset; fnd; say "$((start + 60))" "$A" user; t "the user's words, not a reply" 0
reset; fnd; say "$((start + 60))" 'The fix is in; the tests pass.'; t 'a reply with no aside' 0
reset; fnd; say "$((start + 60))" 'The branch has an unrelated commit, so start a new one.'
  t 'outside the task, but nothing wrong with it' 0
reset; fnd; say "$((start + 60))" 'This looks like a latent bug in the parser.'; t 'a bug named outright' 2
reset; fnd; say "$((start + 60))" 'This is a bug that was already there.'; t 'a bug from before the task' 2
reset; fnd; say "$((now - 10))" "$A"; t 'aside: first stop' 2
  t 'aside: next stop, nothing new since the block' 0
reset; fnd; for i in 1 2 3 4; do say "$((start + 60 + i))" "Side note: thing $i is broken."; done
  t 'four asides: three quoted' 2; has '… and 1 more'

echo "== a session started in a sub-project: its tag and its Scratch folder (D38) =="
# frontend/ is a sub-project; the session started there.
sub() { reset; mkdir -p "$repo/frontend/.agents"; }
ft() { CLAUDE_PROJECT_DIR="$repo/frontend" t "$@"; }
note() { mkdir -p "$vault/Agent/Scratch/d/$1"; echo p > "$vault/Agent/Scratch/d/$1/plan.md"; }
sub; echo b >> "$repo/a.txt"; echo 's #frontend' > "$vault/Agent/Log/today.md"; ft 'Log tagged' 0
sub; echo b >> "$repo/a.txt"; echo 's' > "$vault/Agent/Log/today.md"; ft 'Log without the tag' 2
sub; echo b >> "$repo/a.txt"; echo 's #frontendx' > "$vault/Agent/Log/today.md"; ft 'a longer tag is not it' 2
sub; echo 's' > "$vault/Agent/Log/today.md"; at "$((now - 10))" "$vault/Agent/Log/today.md"; ft 'first stop, untagged' 2
  ft 'next stop, the Log unchanged since' 0
sub; echo 's' > "$vault/Agent/Log/today.md"; t 'started at the root: no tag asked' 0
sub; three; echo 's #frontend' > "$vault/Agent/Log/today.md"; note frontend; ft '3 files, its own Scratch folder' 0
sub; three; echo 's #frontend' > "$vault/Agent/Log/today.md"; note backend; ft '3 files, only another folder written' 2
sub; three; echo 's #frontend' > "$vault/Agent/Log/today.md"; ft '3 files, no Scratch note' 2
sub; echo b >> "$repo/a.txt"; ft 'a sub-project: the heading carries its tag' 2
  has '## Session 1 #frontend'
sub; fnd; say "$((start + 60))" "$A"; ft 'a sub-project: the Findings item carries its tag' 2
  has 'what: `path:line` #frontend'

echo
[ "$fails" -eq 0 ] && echo "all session-log cases pass" || { echo "$fails case(s) FAILED"; exit 1; }
