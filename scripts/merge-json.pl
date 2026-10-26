#!/usr/bin/env perl
# merge-json.pl <file> <template>: add to <file> what <template> has and <file> lacks.
# Missing keys are added, objects merge recursively, arrays gain their missing scalar
# entries; nothing present is changed or removed. A missing <file> is created.
# Prints one "added" line per entry; no output = nothing was missing, file untouched.
# Exit 2 when <file> is not valid JSON (file untouched).
use strict; use warnings; use JSON::PP;

my ($file, $tpl) = @ARGV;
sub slurp { open my $h, '<:raw', $_[0] or die "$_[0]: $!\n"; local $/; <$h> }
my $text = -e $file ? slurp($file) : '{}';
my $d = eval { JSON::PP->new->decode($text) };
ref $d eq 'HASH' or do { print STDERR "not valid JSON: $file\n"; exit 2 };
my $t = JSON::PP->new->decode(slurp($tpl));

my @added;
sub merge {
  my ($have, $want, $at) = @_;
  for my $k (sort keys %$want) {
    my ($h, $w) = ($have->{$k}, $want->{$k});
    if (!exists $have->{$k}) { $have->{$k} = $w; push @added, "$at$k" }
    elsif (ref $h eq 'HASH' && ref $w eq 'HASH') { merge($h, $w, "$at$k.") }
    elsif (ref $h eq 'ARRAY' && ref $w eq 'ARRAY') {
      for my $e (@$w) {
        next if ref $e || grep { !ref && $_ eq $e } @$h;
        push @$h, $e; push @added, "$at$k += $e";
      }
    }
  }
}
merge($d, $t, '');
exit 0 unless @added;

# Keys keep the order they have in <file>; new ones go last.
# ponytail: order = where the key's name first appears in the text, so a key whose name
# also appears earlier as a value can move; an ordered parser if that ever bites.
my $pos = sub { my $i = index($text, qq{"$_[0]"}); $i < 0 ? 9**9 : $i };
my $out = JSON::PP->new->pretty->indent_length(2)->space_before(0)
  ->sort_by(sub { $pos->($JSON::PP::a) <=> $pos->($JSON::PP::b) or $JSON::PP::a cmp $JSON::PP::b })
  ->encode($d);
open my $o, '>:raw', "$file.new" or die "$file.new: $!\n";
print $o $out; close $o or die "$file.new: $!\n";
rename "$file.new", $file or die "$file: $!\n";
print "added   $file: $_\n" for @added;
