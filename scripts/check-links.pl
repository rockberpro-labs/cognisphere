#!/usr/bin/env perl
# check-links.pl <dir>: every [[link]] in the .md files under <dir> must name a note,
# by its path or its bare name. Links inside code (fenced or inline) are not links.
# Prints "<file>: [[link]]" per broken one; no output = all resolve. Exit 1 if any broke.
use strict; use warnings; use File::Find;

my $dir = shift // '.';
chdir $dir or die "$dir: $!\n";
my (@f, %n);
find(sub { push @f, $File::Find::name if /\.md$/ }, '.');
for (@f) { (my $n = $_) =~ s/^\.\/|\.md$//g; $n{$n} = $n{(split m{/}, $n)[-1]} = 1 }
my $bad = 0;
for my $f (@f) {
  open my $h, '<', $f or next;
  local $/; local $_ = <$h>;
  s/```.*?```//gs; s/`[^`\n]*`//g;
  while (/\[\[([^\]|#\\]+)/g) { next if $n{$1}; print "$f: [[$1]]\n"; $bad = 1 }
}
exit $bad;
