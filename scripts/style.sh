#!/usr/bin/env bash
# style.sh <auto|copilot|tutor> [--replace]: the working-style switch (D46). Writes
# templates/styles/<style>.md, word for word, into § Working style of the nearest
# AGENTS.local.md, from the git root up (the one Claude Code and the vault's hooks read,
# so a sub-project switches the root's). Only a known text is swapped: one of the three,
# or the retired Author; the maintainer's own lines around it stay. A section holding
# none of them is the maintainer's own: exit 3 with it printed, and --replace swaps the
# whole section. A missing section goes before the first other one.
# No AGENTS.local.md (a harness-only repo, no vault): one is created at the git root with
# only § Working style, CLAUDE.local.md links to it, and each file .gitignore doesn't
# cover is ignored through .git/info/exclude, so git status shows nothing new.
# Prints "unchanged <style>" or "switched <old> -> <style>" (old: a style, author,
# custom or none), "created <path>" for a new file, then "file <path>".
# Exit 0 done, 2 usage, 3 custom section (untouched), 4 git tracks AGENTS.local.md or
# CLAUDE.local.md (nothing written), 1 other (a symlink could not be made).
here="$(cd "$(dirname "$0")" && pwd)"
styles="$here/../templates/styles"
style="${1:-}"; replace=; [ "${2:-}" = --replace ] && replace=1
[ -f "$styles/$style.md" ] && [ "$style" = "${style##*/}" ] \
  || { echo "usage: style.sh <auto|copilot|tutor> [--replace]" >&2; exit 2; }
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repo" >&2; exit 1; }

d="$top" file=
while :; do
  [ -f "$d/AGENTS.local.md" ] && { file="$d/AGENTS.local.md"; break; }
  [ "$d" = / ] && break
  d="$(dirname "$d")"
done

if [ -z "$file" ]; then
  cd "$top" || exit 1
  for f in AGENTS.local.md CLAUDE.local.md; do
    git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
      && { echo "tracked by git: $f (nothing written)" >&2; exit 4; }
  done
  if [ -f CLAUDE.local.md ] && [ ! -L CLAUDE.local.md ]; then
    mv CLAUDE.local.md AGENTS.local.md && echo "moved   CLAUDE.local.md -> AGENTS.local.md"
  else
    { head -n 1 "$here/../templates/AGENTS.local.md"; echo; } > AGENTS.local.md
    created=1
  fi
  "$here/link.sh" AGENTS.local.md CLAUDE.local.md >/dev/null || exit 1
  exclude="$(git rev-parse --git-path info/exclude)"; mkdir -p "$(dirname "$exclude")"
  for f in AGENTS.local.md CLAUDE.local.md; do
    git check-ignore -q "$f" 2>/dev/null || grep -qxF "/$f" "$exclude" 2>/dev/null \
      || { printf '/%s\n' "$f" >> "$exclude"; echo "added   $exclude: /$f"; }
  done
  file="$top/AGENTS.local.md"
elif git -C "${file%/*}" ls-files --error-unmatch -- AGENTS.local.md >/dev/null 2>&1; then
  echo "tracked by git: $file (nothing written)" >&2; exit 4
fi

# Known texts, by name. Author was install's first style (D7), retired by D46.
export CS_NEW="$(cat "$styles/$style.md")" CS_STYLE_NAME="$style" CS_REPLACE="$replace"
export CS_KNOWN_author="The agent writes and edits code when asked, following the project's rules, and proposes before large or risky changes."
for f in "$styles"/*.md; do n="${f##*/}"; export "CS_KNOWN_${n%.md}=$(cat "$f")"; done

perl -0 -e '
  my ($path) = @ARGV;
  open my $in, "<", $path or die "$path: $!\n"; my $s = <$in>; close $in;
  my $new = $ENV{CS_NEW}; my %known;
  for (grep /^CS_KNOWN_/, keys %ENV) { (my $n = $_) =~ s/^CS_KNOWN_//; $known{$n} = $ENV{$_} }
  my $old;
  if ($s =~ /^## Working style[ \t]*\n(.*?)(?=^## |\z)/ms) {
    my ($from, $len, $body) = ($-[1], $+[1] - $-[1], $1);
    my $flat = sub { my $t = shift; $t =~ s/\s+/ /g; $t =~ s/^ | $//g; $t };
    if (index($flat->($body), $flat->($new)) >= 0) { print "unchanged $ENV{CS_STYLE_NAME}\n"; exit 0 }
    # A known text, possibly wrapped over several lines: match it whitespace-insensitively.
    for my $n (sort keys %known) {
      my $re = join "\\s+", map quotemeta, split " ", $known{$n};
      if ($body =~ s/$re/$new/) { $old = $n; last }
    }
    unless (defined $old) {
      if (!$ENV{CS_REPLACE}) {
        print STDERR "custom text in § Working style (left untouched):\n$body";
        exit 3;
      }
      ($old, $body) = ("custom", "\n$new\n\n");
    }
    $body =~ s/\n*\z/substr($s, $from + $len) eq "" ? "\n" : "\n\n"/e;
    substr($s, $from, $len) = $body;
  } else {
    $old = "none";
    my $section = "## Working style\n\n$new\n";
    if ($s =~ /^## /m) { substr($s, $-[0], 0) = "$section\n" }
    else { $s =~ s/\s*\z//; $s = $s eq "" ? $section : "$s\n\n$section" }
  }
  open my $out, ">", $path or die "$path: $!\n"; print $out $s; close $out;
  print "switched $old -> $ENV{CS_STYLE_NAME}\n";
' "$file" || exit $?
[ -n "${created:-}" ] && echo "created $file"
echo "file    $file"
