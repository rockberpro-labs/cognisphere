#!/usr/bin/env bash
# PreToolUse hook for Edit, Write, MultiEdit and NotebookEdit: scratch-redirect. Refuses
# a write to Claude Code's own stores for agent state, the session scratchpad and
# auto-memory, and points the agent at the vault instead, so the project's working
# state lives where it can be backed up and opened in Obsidian (D36).
#
#   Active only when the nearest AGENTS.local.md, from the cwd's repo up, names a vault
#   ("The vault for this project is `…`") that has an Agent/Scratch/ folder.
#   Refused: a path under a `claude*` folder in the system temp dir that goes through
#   a `scratchpad/` folder (the session scratchpad), and a path under
#   ${CLAUDE_CONFIG_DIR:-~/.claude}/projects/*/memory/ (auto-memory). Plan files are
#   left alone: plan mode needs them, and plan-mirror copies them into Scratch/.
#
# Limit: a write made through Bash (a redirect, cp) isn't seen.
#
# Fails OPEN: any internal error exits 0 so the session is never wedged.
set -uo pipefail

payload="$(cat)" || exit 0
# cwd and the written path, NUL-separated. perl + JSON::PP, as in guard.sh.
{ IFS= read -r -d '' cwd && IFS= read -r -d '' path; } < <(
  printf '%s' "$payload" | perl -MJSON::PP -0777 -ne '
  my $j = eval { decode_json($_) }; exit 0 unless ref $j eq "HASH";
  my $in = ref $j->{tool_input} eq "HASH" ? $j->{tool_input} : {};
  print join("\0", $j->{cwd} // "", $in->{file_path} // $in->{notebook_path} // ""), "\0";
' 2>/dev/null) || exit 0
[ -n "$path" ] || exit 0
[ -n "$cwd" ] && { cd "$cwd" 2>/dev/null || exit 0; }

# Git Bash on Windows mixes C:\, C:/ and /c/ forms; cygpath gives one. Elsewhere, as is.
unix() { if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi; }
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
root="$(unix "$root")"; path="$(unix "$path")"
case "$path" in /*) ;; *) exit 0 ;; esac   # a relative path is inside the cwd: not a store

# The nearest AGENTS.local.md, from the repo up, names the vault (vault-of.sh).
. "$(dirname "$0")/vault-of.sh"
vault="$(vault_of "$root")"
[ -n "$vault" ] || exit 0
vault="$(unix "$vault")"
[ -d "$vault/Agent/Scratch" ] || exit 0
case "$path" in "$root"/*|"$vault"/*) exit 0 ;; esac

config="$(unix "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")"
tmp="$(unix "${TMPDIR:-/tmp}")"
day="$vault/Agent/Scratch/$(date +%F)"
store=
case "$path" in "$config"/projects/*/memory/*) store=memory ;; esac
if [ -z "$store" ]; then
  # Case-insensitive: Windows' temp dir is spelled Temp or temp depending on who asks.
  shopt -s nocasematch
  case "$path" in
    "$tmp"/claude*/scratchpad/*|/tmp/claude*/scratchpad/*|*/temp/claude*/scratchpad/*) store=scratchpad ;;
  esac
  shopt -u nocasematch
fi
[ -n "$store" ] || exit 0

if [ "$store" = scratchpad ]; then
  {
    echo "scratch-redirect: this project keeps the agent's working files in its vault, not in"
    echo "Claude Code's session scratchpad, so they travel with the project (backups, Obsidian)."
    echo "Write \`$day/${path##*/}\` instead when it is output worth keeping: a note, a script you"
    echo "wrote, a result. Throwaway material (a test repo, a download, build output) isn't:"
    echo "put it in a \`mktemp -d\` folder, outside both the vault and the scratchpad."
  } >&2
else
  {
    echo "scratch-redirect: this project keeps the agent's state in its vault, not in Claude Code's"
    echo "auto-memory ($path). Put it where it belongs instead:"
    echo "  - how the maintainer wants you to work -> $vault/Agent/State/Preferences.md (with the reason)"
    echo "  - what to know about the maintainer    -> $vault/Agent/State/Preferences.md"
    echo "  - lasting truth about the code         -> the area's .agents/memory/ note (or tell the maintainer)"
    echo "  - a question or decision left open     -> $vault/Agent/State/Open Threads.md"
    echo "  - something noticed outside the task   -> $vault/Agent/State/Findings.md"
    echo "  - a correction or decision made        -> $vault/Agent/Log/$(date +%F).md"
    echo "  - output for this task                 -> $day/<topic>.md"
  } >&2
fi
exit 2
