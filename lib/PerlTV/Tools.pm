package PerlTV::Tools;
use strict;
use warnings;

use Path::Tiny ();
use Text::Markdown ();

use base 'Exporter';
our @EXPORT_OK = qw(read_file youtube_thumbnail %languages);

our %languages = (
	he => 'Hebrew',
);

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

	if ($video{language}) {
		$video{language_in_english} = $languages{ $video{language} };
		$video{title} .= " ($video{language_in_english})";
	}

	$video{format} ||= 'html';

	if ($video{description}) {
		if ($video{format} eq 'markdown') {
			my $md = Text::Markdown->new;
			$video{description} = $md->markdown( $video{description} );
		}
	}

	return \%video;
}

sub youtube_thumbnail {
	my ($id) = @_;
	return "http://img.youtube.com/vi/$id/default.jpg";
}

1;

