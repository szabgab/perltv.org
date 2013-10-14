package PerlTV::Tools;
use strict;
use warnings;

use Path::Tiny ();

use base 'Exporter';
our @EXPORT_OK = qw(read_file);

sub read_file {
	my ($file) = @_;

	my %video;
	my $section;
	foreach my $line (Path::Tiny::path($file)->lines_utf8) {
		if ($line =~ /^__(\w+)__$/) {
			$section = lc $1;
			next;
		}
		if ($section) {
			$video{$section} .= $line;
			next;
		}
		next if $line =~ /^\s*(#.*)?$/;
		chomp $line;
		$line =~ s/\s+$//;
		my ($key, $value) = split /:\s*/, $line, 2;
		if ($key =~ /^(modules|tags)$/) {
			$video{$key} = [ split /\s*,\s*/, $value ];
		} else {
			$video{$key} = $value;
		}
	}
	return \%video;
}

1;

