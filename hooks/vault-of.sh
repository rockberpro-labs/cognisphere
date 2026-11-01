#!/usr/bin/env bash
# vault-of.sh: sourced by the vault's hooks. vault_of <dir> prints the vault that the
# nearest AGENTS.local.md names ("The vault for this project is `…`"), looking in <dir>
# (the session's git root) and then each folder above it, so a session in a sub-project
# that is a repo of its own finds the root's vault (D38), but only when that repo's own
# .agents/ or .claude/settings.local.json points at the vault (D51). Prints nothing when
# none does.
# The vault path is whatever the local configuration says, never derived here.
#
# subproject_of <dir> sets home, the folder whose AGENTS.local.md names the vault, and
# tag, the sub-project <dir> sits in: the nearest folder from <dir> up, below home, with
# an .agents/ of its own, as its path from home (frontend, apps/web). Empty tag at the
# root or when no vault is named. Characters an Obsidian tag can't hold become `-`.
# <dir> is the folder the session started in ($CLAUDE_PROJECT_DIR), not the cwd.
vault_named() {
  [ -f "$1/AGENTS.local.md" ] || return 0
  sed -n 's/^- The vault for this project is `\([^`]*\)`.*/\1/p' "$1/AGENTS.local.md" 2>/dev/null | head -n 1
}

configured_for() {
  local n="${2%/}"; n="${n##*/}"
  [ -n "$n" ] || return 1
  grep -qF "Projects/$n" "$1/.agents/settings.local.json" "$1/.claude/settings.local.json" 2>/dev/null
}

vault_of() {
  local start="$1" d="$1" v p
  while [ -n "$d" ]; do
    v="$(vault_named "$d")"
    if [ -n "$v" ]; then
      # A vault found above the repo counts only when the repo's own local settings
      # point at it (what /cognisphere:vault --project writes): a repo never set up for
      # a vault is left alone (D51).
      [ "$d" = "$start" ] || configured_for "$start" "$v" || return 0
      case "$v" in '~/'*) v="$HOME/${v#'~/'}" ;; esac
      printf '%s\n' "$v"; return 0
    fi
    # dirname stops moving at the top: / on Unix, but C: or . on Windows paths.
    p="$(dirname "$d")"; [ "$p" = "$d" ] && break
    d="$p"
  done
  return 0
}

subproject_of() {
  local d="$1" sub= p
  home= tag=
  while [ -n "$d" ]; do
    if [ -n "$(vault_named "$d")" ]; then
      home="$d"
      [ -n "$sub" ] && tag="$(printf '%s' "${sub#"$d"/}" | tr -c 'A-Za-z0-9_/-' -)"
      return 0
    fi
    [ -z "$sub" ] && [ -d "$d/.agents" ] && sub="$d"
    p="$(dirname "$d")"; [ "$p" = "$d" ] && break
    d="$p"
  done
  return 0
}
