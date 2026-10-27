#!/usr/bin/env bash
# vault-of.sh: sourced by the vault's hooks. vault_of <dir> prints the vault that the
# nearest AGENTS.local.md names ("The vault for this project is `…`"), looking in <dir>
# (the session's git root) and then each folder above it, so a session in a sub-project
# that is a repo of its own finds the root's vault (D38). Prints nothing when none does.
# The vault path is whatever the local configuration says, never derived here.
vault_of() {
  local d="$1" v
  while [ -n "$d" ]; do
    if [ -f "$d/AGENTS.local.md" ]; then
      v="$(sed -n 's/^- The vault for this project is `\([^`]*\)`.*/\1/p' "$d/AGENTS.local.md" 2>/dev/null | head -n 1)"
      if [ -n "$v" ]; then
        case "$v" in '~/'*) v="$HOME/${v#'~/'}" ;; esac
        printf '%s\n' "$v"; return 0
      fi
    fi
    [ "$d" = / ] && break
    d="$(dirname "$d")"
  done
  return 0
}
