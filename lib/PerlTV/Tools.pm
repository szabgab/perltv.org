package PerlTV::Tools;
use strict;
use warnings;

use Path::Tiny ();
use Text::Markdown ();

use base 'Exporter';
our @EXPORT_OK = qw(read_file youtube_thumbnail %languages);

our %languages = (
	he => 'Hebrew',
	nl => 'Dutch',
	de => 'German',
	en => 'English',
);

sub read_file {
	my ($file) = @_;

	my %data;
	my $section;
	foreach my $line (Path::Tiny::path($file)->lines_utf8) {
		if ($line =~ /^__(\w+)__$/) {
			$section = lc $1;
			next;
		}
		if ($section) {
			$data{$section} .= $line;
			next;
		}
		next if $line =~ /^\s*(#.*)?$/;
		chomp $line;
		$line =~ s/\s+$//;
		my ($key, $value) = split /:\s*/, $line, 2;
		if ($key =~ /^(modules|tags)$/) {
			$data{$key} = [ split /\s*,\s*/, $value ];
		} else {
			$data{$key} = $value;
		}
	}

	# default language is English unless language is defined in video
	$data{language} ||= 'en';

	die "Missing language '$data{language}' in '$file'" if not $languages{ $data{language} };
	
	$data{language_in_english} = $languages{ $data{language} };

	$data{format} ||= 'html';

	if ($data{description}) {
		if ($data{format} eq 'markdown') {
			my $md = Text::Markdown->new;
			$data{description} = $md->markdown( $data{description} );
		}
	}

	return \%data;
}

sub youtube_thumbnail {
	my ($id) = @_;
	return "http://img.youtube.com/vi/$id/default.jpg";
}

1;

