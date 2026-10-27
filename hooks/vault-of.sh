#!/usr/bin/env bash
# vault-of.sh: sourced by the vault's hooks. vault_of <dir> prints the vault that the
# nearest AGENTS.local.md names ("The vault for this project is `…`"), looking in <dir>
# (the session's git root) and then each folder above it, so a session in a sub-project
# that is a repo of its own finds the root's vault (D38). Prints nothing when none does.
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

vault_of() {
  local d="$1" v
  while [ -n "$d" ]; do
    v="$(vault_named "$d")"
    if [ -n "$v" ]; then
      case "$v" in '~/'*) v="$HOME/${v#'~/'}" ;; esac
      printf '%s\n' "$v"; return 0
    fi
    [ "$d" = / ] && break
    d="$(dirname "$d")"
  done
  return 0
}

subproject_of() {
  local d="$1" sub=
  home= tag=
  while [ -n "$d" ]; do
    if [ -n "$(vault_named "$d")" ]; then
      home="$d"
      [ -n "$sub" ] && tag="$(printf '%s' "${sub#"$d"/}" | tr -c 'A-Za-z0-9_/-' -)"
      return 0
    fi
    [ -z "$sub" ] && [ -d "$d/.agents" ] && sub="$d"
    [ "$d" = / ] && break
    d="$(dirname "$d")"
  done
  return 0
}
