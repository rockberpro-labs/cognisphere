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

# An existing settings.json with its own key order, one deny entry of its own, a number
# written as 2.50, and a hook entry whose "matcher" comes before its "hooks".
mkdir -p .agents && printf '{\n  "zeta": 1,\n  "permissions": {\n    "deny": ["Bash(rm:*)"]\n  },\n  "alpha": 2.50,\n  "hooks": {\n    "PreToolUse": [{ "matcher": "Bash", "hooks": [] }]\n  }\n}\n' > .agents/settings.json
echo "# Demo" > CLAUDE.md

out="$(bash "$S/scaffold.sh")"; r=$?
ok "scaffold exits 0"                 '[ $r = 0 ]'
ok ".claude is a link"                '[ -L .claude ]'
ok "CLAUDE.md moved to AGENTS.md"     '[ -L CLAUDE.md ] && grep -q "# Demo" AGENTS.md'
ok "deny entry kept, template added"  'grep -q "Bash(rm:\*)" .agents/settings.json && grep -q "git add" .agents/settings.json'
ok "key order kept"                   '[ "$(grep -o "\"[a-z]*\":" .agents/settings.json | head -3 | tr -d "\n")" = "\"zeta\":\"permissions\":\"deny\":" ]'
ok "nested key order kept"            'grep -A1 "\"matcher\"" .agents/settings.json | grep -qF "\"hooks\": []"'
ok "number form kept"                 'grep -qF "\"alpha\": 2.50," .agents/settings.json'
ok "local files ignored"              'grep -qx AGENTS.local.md .gitignore && grep -qx CLAUDE.local.md .gitignore'
before="$(cat .agents/settings.json .gitignore .agents/.gitignore)"
out="$(bash "$S/scaffold.sh")"; r=$?
ok "scaffold rerun creates nothing"   '[ $r = 0 ] && ! printf "%s" "$out" | grep -q "^created\|^added" && [ "$before" = "$(cat .agents/settings.json .gitignore .agents/.gitignore)" ]'

echo "The agent writes code." > "$tmp/style"
ok "scaffolded repo is cognisphere's" 'bash "$S/names.sh" demo | grep -qx repo_layer=cognisphere'
out="$(bash "$S/configure.sh" demo "$tmp/style")"; r=$?
vault="$(bash "$S/names.sh" demo | sed -n 's/^vault=//p')"
ok "configure exits 0"                '[ $r = 0 ] && ! printf "%s" "$out" | grep -q "NOT IGNORED"'
ok "vault path is not MSYS-style"     '! printf "%s" "$vault" | grep -q "^/[a-z]/"'
ok "AGENTS.local.md names the vault"  'grep -qF "$vault/Agent/00 Home.md" AGENTS.local.md && grep -q "The agent writes code." AGENTS.local.md'
ok "end-of-session line"              'grep -qF "Before the last reply" AGENTS.local.md'
ok "findings lines"                  'grep -qF "State/Findings.md" AGENTS.local.md && grep -qF "Asked about known issues" AGENTS.local.md'
ok "settings.local.json entries"      'grep -qF "Edit(~/Cognisphere/demo/Human/**)" .agents/settings.local.json'
ok "CLAUDE.local.md is a link"        '[ -L CLAUDE.local.md ]'
ok "no Repo layer section"            '! grep -q "^## Repo layer" AGENTS.local.md && [ "$(tail -c1 AGENTS.local.md | od -An -c | tr -d " ")" = "\n" ]'
printf '# Mine\n\n## Working style\n\nTutor.\n' > AGENTS.local.md
bash "$S/configure.sh" demo "$tmp/style" >/dev/null
ok "only the missing section added"   '[ "$(grep -c "^## " AGENTS.local.md)" = 2 ] && grep -q "^Tutor.$" AGENTS.local.md && ! grep -q "The agent writes code." AGENTS.local.md'
echo "{ broken" > .agents/settings.local.json
bash "$S/configure.sh" demo "$tmp/style" >/dev/null 2>&1; r=$?
ok "invalid JSON stops, untouched"    '[ $r = 2 ] && [ "$(cat .agents/settings.local.json)" = "{ broken" ]'

out="$(bash "$S/seed-vault.sh" demo)"
ok "seed creates Home and today"      '[ -f "$vault/Agent/00 Home.md" ] && [ -f "$vault/Agent/Log/$(date +%F).md" ]'
ok "seed creates Findings"           '[ -f "$vault/Agent/State/Findings.md" ]'
ok "placeholders filled"              '! grep -rq "{{" "$vault/Agent" "$vault/Human"'
out="$(bash "$S/seed-vault.sh" demo)"
ok "seed rerun creates nothing"       '! printf "%s" "$out" | grep -q "^created"'
ok "seeded links resolve"             'perl "$S/check-links.pl" "$vault/Agent"'
echo "see [[Nowhere]] but not \`[[Code]]\`" >> "$vault/Agent/Scratch/README.md"
ok "broken link reported"             '[ "$(perl "$S/check-links.pl" "$vault/Agent")" = "./Scratch/README.md: [[Nowhere]]" ]'

# Untouched (D30, D31): a repo with a harness of its own, committed, so names.sh finds no
# cognisphere rule. Nothing git tracks may change and git status must show nothing new,
# with .claude absent or linked to .agents.
for kind in plain linked; do
  u="$tmp/untouched-$kind"; mkdir -p "$u/.agents/rules" && cd "$u" && git init -q && git config user.email t@t && git config user.name t
  echo "# Theirs" > AGENTS.md; echo "rule" > .agents/rules/x.md
  [ $kind = linked ] && { ln -s .agents .claude; ln -s AGENTS.md CLAUDE.md; echo settings.local.json > .agents/.gitignore; }
  git add -A && git commit -qm harness
  ok "untouched ($kind) detected"              'bash "$S/names.sh" demo | grep -qx repo_layer=untouched'
  out="$(bash "$S/configure.sh" demo "$tmp/style")"; r=$?
  ok "untouched ($kind) exits 0, all ignored"  '[ $r = 0 ] && ! printf "%s" "$out" | grep -q "NOT IGNORED"'
  ok "untouched ($kind) leaves git clean"      '[ -z "$(git status --porcelain)" ]'
  ok "untouched ($kind) settings where read"   'grep -qF "Edit(~/Cognisphere/demo/Human/**)" .claude/settings.local.json'
  ok "untouched ($kind) Repo layer section"    'grep -q "^## Repo layer" AGENTS.local.md && [ -L CLAUDE.local.md ]'
  before="$(cat .git/info/exclude)"
  bash "$S/configure.sh" demo "$tmp/style" >/dev/null
  ok "untouched ($kind) rerun adds nothing"    '[ "$before" = "$(cat .git/info/exclude)" ] && [ "$(grep -c "^## " AGENTS.local.md)" = 3 ]'
done
ok "linked: .agents/.gitignore suffices"      '! grep -q settings.local.json .git/info/exclude'
u="$tmp/untouched-tracked"; mkdir -p "$u" && cd "$u" && git init -q && git config user.email t@t && git config user.name t
echo "# Team-wide" > AGENTS.local.md && git add AGENTS.local.md && git commit -qm local
bash "$S/configure.sh" demo "$tmp/style" >/dev/null 2>&1; r=$?
ok "untouched stops on a tracked file"        '[ $r = 4 ] && [ ! -e .claude ] && [ -z "$(git status --porcelain)" ] && ! grep -q "^/" .git/info/exclude'
printf '# Mine\n\n## Working style\n\nTutor.\n\n## Agent workspace\n\n- x\n' > "$tmp/existing.md"
u="$tmp/untouched-existing"; mkdir -p "$u" && cd "$u" && git init -q && cp "$tmp/existing.md" AGENTS.local.md
bash "$S/configure.sh" demo "$tmp/style" >/dev/null
ok "untouched adds § Repo layer to an existing file" '[ "$(grep -c "^## " AGENTS.local.md)" = 3 ] && grep -q "^Tutor.$" AGENTS.local.md && [ -z "$(git status --porcelain)" ]'
mkdir -p .agents/rules && cp "$S/../templates/rules/memory.md" .agents/rules/
ok "§ Repo layer keeps it untouched"  'bash "$S/names.sh" demo | grep -qx repo_layer=untouched'

# repo-layer (D31): the harness added later to the vault-only repo above. .claude was a
# real folder holding settings.local.json; scaffold links it once that is merged.
git config user.email t@t && git config user.name t
mkdir -p .agents && mv .claude/settings.local.json .agents/ && rmdir .claude
bash "$S/scaffold.sh" >/dev/null
out="$(bash "$S/repo-layer.sh")"
ok "repo-layer drops § Repo layer"    '! grep -q "^## Repo layer" AGENTS.local.md && grep -q "^## Agent workspace" AGENTS.local.md && [ "$(tail -c1 AGENTS.local.md | od -An -c | tr -d " ")" = "\n" ]'
ok "repo-layer drops covered excludes" '! grep -q "^/" .git/info/exclude'
ok "local files still ignored"        'git check-ignore AGENTS.local.md CLAUDE.local.md .agents/settings.local.json | [ "$(wc -l)" = 3 ]'
ok "repo layer now cognisphere's"     'bash "$S/names.sh" demo | grep -qx repo_layer=cognisphere'
out="$(bash "$S/repo-layer.sh")"
ok "repo-layer rerun changes nothing" '[ -z "$out" ]'

# user-settings: agent-kit, a second cognisphere and a guard hook are each reported;
# a plugin left disabled and an unrelated hook are not.
u="$tmp/user-settings.json"
ok "no user settings, no output"      '[ -z "$(perl "$S/user-settings.pl" "$tmp/none.json")" ]'
printf '{ "enabledPlugins": { "cognisphere@cognisphere": true, "agent-kit@agent-kit": false },\n  "hooks": { "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash ~/bin/encoding-guard.sh" }] }] } }\n' > "$u"
ok "clean user settings, no output"   '[ -z "$(perl "$S/user-settings.pl" "$u")" ]'
printf '{ "enabledPlugins": { "cognisphere@cognisphere": true, "cognisphere@fork": true, "agent-kit@agent-kit": true },\n  "hooks": { "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash ~/.agents/hooks/master-guard.sh" }] }] } }\n' > "$u"
out="$(perl "$S/user-settings.pl" "$u")"
ok "agent-kit reported"               'printf "%s" "$out" | grep -qF "\"agent-kit@agent-kit\" runs the same guards"'
ok "second cognisphere reported"      'printf "%s" "$out" | grep -qF "more than once"'
ok "guard hook reported"              'printf "%s" "$out" | grep -qF "master-guard.sh\" runs a guard"'
echo "{ broken" > "$u"
perl "$S/user-settings.pl" "$u" >/dev/null 2>&1; r=$?
ok "invalid user settings exits 2"    '[ $r = 2 ]'

# coupling: 3 commits touch src/, 2 of them also the doc.
c="$tmp/coupling"; mkdir -p "$c/src" "$c/docs" && cd "$c" && git init -q && git config user.email t@t && git config user.name t && git config core.autocrlf false
for i in 1 2 3; do echo $i > src/a.c; [ $i = 3 ] || echo $i > docs/notes.md; git add src docs && git commit -qm $i; done
echo x > docs/notes.md && git commit -qam doc-only
ok "coupling counts the area"         'bash "$S/coupling.sh" docs/notes.md "src/**" | grep -q "^2 of 3 .* blocked 1$"'

echo "failures=$fails"
[ "$fails" -eq 0 ]
