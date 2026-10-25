#!/usr/bin/env bash
# Installs or updates the cognisphere plugin for Claude Code. Idempotent.
#   curl -fsSL https://raw.githubusercontent.com/rockberpro/cognisphere/main/install.sh | bash
# COGNISPHERE_REPO overrides the marketplace source (a mirror, or a local path for testing).
set -euo pipefail

repo="${COGNISPHERE_REPO:-https://github.com/rockberpro/cognisphere.git}"
marketplace=cognisphere
plugin=cognisphere@cognisphere

say()  { printf 'cognisphere: %s\n' "$*"; }
fail() { printf 'cognisphere: %s\n' "$*" >&2; exit 1; }

case "$(uname -s)" in
  Linux|Darwin) ;;
  *) fail "Linux and macOS only (found $(uname -s))." ;;
esac
command -v claude >/dev/null 2>&1 || fail "claude not found. Install Claude Code first: https://code.claude.com"
command -v git    >/dev/null 2>&1 || fail "git not found."
perl -MJSON::PP -e 1 2>/dev/null  || fail "perl with JSON::PP not found; the guards need it (it ships with git on most systems)."

# Prints the names (or ids) found under KEY in a JSON array read from stdin.
json_field() { perl -MJSON::PP -0777 -ne 'my $d = eval { decode_json($_) } || []; print "$_->{'"$1"'}\n" for @$d'; }

if claude plugin marketplace list --json | json_field name | grep -qxF "$marketplace"; then
  say "marketplace '$marketplace' already added; updating it"
  claude plugin marketplace update "$marketplace"
else
  say "adding marketplace from $repo"
  claude plugin marketplace add "$repo"
fi

installed="$(claude plugin list --json | json_field id)"
if printf '%s\n' "$installed" | grep -qxF "$plugin"; then
  say "$plugin already installed; updating it"
  claude plugin update "$plugin"
else
  say "installing $plugin"
  claude plugin install "$plugin"
fi

if ak="$(printf '%s\n' "$installed" | grep '^agent-kit@')"; then
  say "WARNING: agent-kit is installed too ($ak). Its guards would run twice next to cognisphere's."
  say "         cognisphere replaces it. Remove it with:"
  printf '%s\n' "$ak" | while IFS= read -r id; do printf '           claude plugin uninstall %s\n' "$id"; done
fi

say "done. Next: in a git repository, start claude and run /cognisphere:install"
