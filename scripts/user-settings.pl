#!/usr/bin/env perl
# user-settings.pl [file]: what in the user-level settings makes the guards run twice.
# Default file: ${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json. Read-only. Prints one line
# per finding: agent-kit enabled, more than one cognisphere enabled, a hook that runs a
# guard script. No output = nothing to report, or no such file.
# Exit 2 when the file is not valid JSON.
use strict; use warnings; use JSON::PP;

my $file = $ARGV[0] // (($ENV{CLAUDE_CONFIG_DIR} // "$ENV{HOME}/.claude") . '/settings.json');
exit 0 unless -e $file;
open my $h, '<:raw', $file or die "$file: $!\n";
my $j = eval { JSON::PP->new->decode(do { local $/; <$h> }) };
ref $j eq 'HASH' or do { print STDERR "not valid JSON: $file\n"; exit 2 };

my %on = %{ ref $j->{enabledPlugins} eq 'HASH' ? $j->{enabledPlugins} : {} };
my @on = grep { $on{$_} } sort keys %on;
print "$file: enabledPlugins \"$_\" runs the same guards as cognisphere\n" for grep { /^agent-kit@/ } @on;
my @cs = grep { /^cognisphere@/ } @on;
print "$file: enabledPlugins ", join(', ', map { "\"$_\"" } @cs), ": cognisphere installed more than once\n" if @cs > 1;

my %hooks = %{ ref $j->{hooks} eq 'HASH' ? $j->{hooks} : {} };
for my $event (sort keys %hooks) {
  for my $entry (ref $hooks{$event} eq 'ARRAY' ? @{ $hooks{$event} } : ()) {
    for my $hook (ref $entry eq 'HASH' && ref $entry->{hooks} eq 'ARRAY' ? @{ $entry->{hooks} } : ()) {
      my $cmd = ref $hook eq 'HASH' ? $hook->{command} // '' : '';
      print "$file: $event hook \"$cmd\" runs a guard the plugin already runs\n"
        if $cmd =~ m{(?:^|[/\\"\s])(?:guard|master-guard|secret-guard|memory-drift-guard)\.sh\b};
    }
  }
}
