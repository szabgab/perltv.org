#!/usr/bin/env perl
use Moo;
use Path::Tiny qw(path);
use JSON::Tiny ();



my @files = glob "data/*";
my %data;
foreach my $f (@files) {
	my $section;
	my %video;
	foreach my $line (path($f)->lines_utf8) {
		if ($line =~ /^__(\w+)__$/) {
			$section = $1;
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
			$video{$key} = split /\s*,\s*/, $value;
		} else {
			$video{$key} = $value;
		}
	}
	$data{$f} = \%video;
}

my $json = JSON::Tiny->new;
$data{_comment} = 'This is a generated file, please do NOT edit directly';
path('video.json')->spew_utf8(  $json->encode({ videos => \%data }) );
