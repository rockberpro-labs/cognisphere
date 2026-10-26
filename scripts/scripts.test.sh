#!/usr/bin/env bash
# Self-check for scripts/:  bash scripts/scripts.test.sh
#
# Runs scaffold, configure and seed in a throwaway repo with a throwaway $HOME, twice,
# so the real worktree and vault are never touched. Exits non-zero if any case regresses.
set -uo pipefail

S="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in "$S"/*.sh; do bash -n "$f" || exit 1; [ -x "$f" ] || { echo "missing exec bit: $f"; exit 1; }; done
for f in "$S"/*.pl; do perl -c "$f" 2>/dev/null || { echo "does not compile: $f"; exit 1; }; done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"; mkdir -p "$HOME"
repo="$tmp/demo"; mkdir -p "$repo" && cd "$repo" && git init -q -b work || exit 1

fails=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails+1)); fi; }

# An existing settings.json with its own key order and one deny entry of its own.
mkdir -p .agents && printf '{\n  "zeta": 1,\n  "permissions": {\n    "deny": ["Bash(rm:*)"]\n  },\n  "alpha": 2\n}\n' > .agents/settings.json
echo "# Demo" > CLAUDE.md

out="$(bash "$S/scaffold.sh")"; r=$?
ok "scaffold exits 0"                 '[ $r = 0 ]'
ok ".claude is a link"                '[ -L .claude ]'
ok "CLAUDE.md moved to AGENTS.md"     '[ -L CLAUDE.md ] && grep -q "# Demo" AGENTS.md'
ok "deny entry kept, template added"  'grep -q "Bash(rm:\*)" .agents/settings.json && grep -q "git add" .agents/settings.json'
ok "key order kept"                   '[ "$(grep -o "\"[a-z]*\":" .agents/settings.json | head -3 | tr -d "\n")" = "\"zeta\":\"permissions\":\"deny\":" ]'
ok "local files ignored"              'grep -qx AGENTS.local.md .gitignore && grep -qx CLAUDE.local.md .gitignore'
before="$(cat .agents/settings.json .gitignore .agents/.gitignore)"
out="$(bash "$S/scaffold.sh")"; r=$?
ok "scaffold rerun creates nothing"   '[ $r = 0 ] && ! printf "%s" "$out" | grep -q "^created\|^added" && [ "$before" = "$(cat .agents/settings.json .gitignore .agents/.gitignore)" ]'

echo "The agent writes code." > "$tmp/style"
out="$(bash "$S/configure.sh" demo "$tmp/style")"; r=$?
vault="$(bash "$S/names.sh" demo | sed -n 's/^vault=//p')"
ok "configure exits 0"                '[ $r = 0 ] && ! printf "%s" "$out" | grep -q "NOT IGNORED"'
ok "vault path is not MSYS-style"     '! printf "%s" "$vault" | grep -q "^/[a-z]/"'
ok "AGENTS.local.md names the vault"  'grep -qF "$vault/Agent/00 Home.md" AGENTS.local.md && grep -q "The agent writes code." AGENTS.local.md'
ok "settings.local.json entries"      'grep -qF "Edit(~/Cognisphere/demo/Human/**)" .agents/settings.local.json'
ok "CLAUDE.local.md is a link"        '[ -L CLAUDE.local.md ]'
printf '# Mine\n\n## Working style\n\nTutor.\n' > AGENTS.local.md
bash "$S/configure.sh" demo "$tmp/style" >/dev/null
ok "only the missing section added"   '[ "$(grep -c "^## " AGENTS.local.md)" = 2 ] && grep -q "^Tutor.$" AGENTS.local.md && ! grep -q "The agent writes code." AGENTS.local.md'
echo "{ broken" > .agents/settings.local.json
bash "$S/configure.sh" demo "$tmp/style" >/dev/null 2>&1; r=$?
ok "invalid JSON stops, untouched"    '[ $r = 2 ] && [ "$(cat .agents/settings.local.json)" = "{ broken" ]'

out="$(bash "$S/seed-vault.sh" demo)"
ok "seed creates Home and today"      '[ -f "$vault/Agent/00 Home.md" ] && [ -f "$vault/Agent/Log/$(date +%F).md" ]'
ok "placeholders filled"              '! grep -rq "{{" "$vault/Agent" "$vault/Human"'
out="$(bash "$S/seed-vault.sh" demo)"
ok "seed rerun creates nothing"       '! printf "%s" "$out" | grep -q "^created"'
ok "seeded links resolve"             'perl "$S/check-links.pl" "$vault/Agent"'
echo "see [[Nowhere]] but not \`[[Code]]\`" >> "$vault/Agent/Scratch/README.md"
ok "broken link reported"             '[ "$(perl "$S/check-links.pl" "$vault/Agent")" = "./Scratch/README.md: [[Nowhere]]" ]'

echo "failures=$fails"
[ "$fails" -eq 0 ]
