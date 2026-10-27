#!/usr/bin/env bash
# PostToolUse hook for Edit, Write, MultiEdit and NotebookEdit: scratch-first. After an
# edit of a repo file, reminds the agent to write its note in the vault's Scratch/ when
# the session has none yet: the plan AGENTS.local.md asks for before the first edit of a
# task (D35), and again when the note has fallen behind the work (D36).
#
#   Active only when AGENTS.local.md names a vault ("The vault for this project is `…`")
#   that has a Scratch/ folder. Edits outside the repo (the vault itself included) pass.
#   A note counts when a file in a day folder, Scratch/YYYY-MM-DD/, was modified after
#   the session began (its first transcript timestamp); a loose file in Scratch/ doesn't.
#   Once one exists, it stays quiet until 3 or more repo files (committed or not) have
#   changed since the newest Scratch write: then the note is due an update.
#   A session started in a sub-project (D38, vault-of.sh) counts only notes in its own
#   folder, Scratch/YYYY-MM-DD/<tag>/, and is pointed there.
#
# Soft (D37): it never blocks an edit, and it says each thing once. A stamp per session
# in the temp dir holds what it last reminded of (no note, or the note it found behind),
# so the next reminder comes only after the agent writes in Scratch/ and falls behind
# again. Limit: an edit made through Bash (sed -i, a heredoc) isn't seen.
#
# Never blocks: it exits 0 whatever happens.
set -uo pipefail

payload="$(cat)" || exit 0
# cwd, the edited path, the session's start (epoch seconds, from the first `timestamp`
# in the transcript) and its id, NUL-separated. perl + JSON::PP, as in guard.sh.
{ IFS= read -r -d '' cwd && IFS= read -r -d '' path && IFS= read -r -d '' start \
  && IFS= read -r -d '' sid; } < <(
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
  (my $sid = $j->{session_id} // "") =~ s/[^A-Za-z0-9_-]//g;
  print join("\0", $j->{cwd} // "", $in->{file_path} // $in->{notebook_path} // "", $start, $sid || "none"), "\0";
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

# The nearest AGENTS.local.md, from the repo up, names the vault (vault-of.sh).
. "$(dirname "$0")/vault-of.sh"
vault="$(vault_of "$root")"
[ -n "$vault" ] || exit 0
scratch="$(unix "$vault")/Agent/Scratch"
[ -d "$scratch" ] || exit 0
subproject_of "${CLAUDE_PROJECT_DIR:-$PWD}"
today="$(date +%F)${tag:+/$tag}"

# The newest file written this session in a day folder (its <tag>/ in a sub-project's
# session): "<mtime>\t<path>", or nothing.
last="$(perl -MFile::Find -e '
  my ($t, $s, $g) = @ARGV; my ($m, $p) = (0, ""); $g = length $g ? "\Q$g\E/" : "";
  find({ no_chdir => 1, wanted => sub {
    return unless -f && m{^\Q$s\E/\d{4}-\d\d-\d\d/$g};
    my $x = (stat _)[9]; ($m, $p) = ($x, $_) if $x > $t && $x > $m } }, $s);
  print "$m\t$p\n" if $p;' "$start" "$scratch" "$tag" 2>/dev/null)"

# remind <key> <text>: the text to the agent as context, unless <key> is what this session
# was last reminded of.
stamp="${TMPDIR:-/tmp}/cognisphere-scratch-first.$sid"
remind() {
  [ "$(cat "$stamp" 2>/dev/null)" = "$1" ] && exit 0
  printf '%s\n' "$1" > "$stamp" 2>/dev/null
  perl -MJSON::PP -e 'print encode_json({ hookSpecificOutput => { hookEventName => "PostToolUse",
    additionalContext => $ARGV[0] } })' "$2" 2>/dev/null
  exit 0
}

if [ -z "$last" ]; then
  remind none "scratch-first: you edited a repo file, and there is no working note in $scratch/ yet this session. Write \`$scratch/$today/<topic>.md\` now: the plan, the files you'll touch and the open questions (a line or two is enough for a small fix). Keep it current as you go; at the end, promote what matters to the Log, Open Threads or Findings. The day folder stays: it's the history."
fi

# Repo files the session touched, committed or not, changed after that newest note.
since="${last%%$'\t'*}"; note="${last#*$'\t'}"
behind="$(cd "$root" && { git log -z --since="@$start" --name-only --format= 2>/dev/null
  git diff -z --name-only HEAD 2>/dev/null; git ls-files -z --others --exclude-standard 2>/dev/null; } \
  | perl -0 -e 'my $t = shift; my %s;
      while (<STDIN>) { chomp; next if !length || $s{$_}++; print "$_\n" if -f && (stat _)[9] > $t }' "$since" 2>/dev/null)"
n="$(printf '%s' "$behind" | grep -c .)"
[ "${n:-0}" -ge 3 ] || exit 0

remind "behind $since" "scratch-first: $n repo files changed since you last wrote in Scratch/ (${note#"$scratch/"}): $(printf '%s\n' "$behind" | sed -n '1,5p' | paste -sd, - | sed 's/,/, /g'). Bring the note up to date (what's done, what changed in the plan, what's still open), or start \`$scratch/$today/<topic>.md\` for a new task."
