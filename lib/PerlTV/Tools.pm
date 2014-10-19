package PerlTV::Tools;
use strict;
use warnings;

use Path::Tiny ();
use Text::Markdown ();

use base 'Exporter';
our @EXPORT_OK = qw(read_file youtube_thumbnail get_atom_xml %languages);

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

sub fix_ts {
	my ($ts) = @_;

	if ($ts =~ /^\d\d\d\d-\d\d-\d\d$/) {
		$ts .= 'T12:00:00Z'; 
	} elsif ($ts =~ /^(\d\d\d\d-\d\d-\d\d) (\d\d:\d\d:\d\d)$/) {
		$ts = $1 . 'T' . $2 . 'Z';
	} else {
		warn "ts '$ts' incorrect";
	}
	return $ts;
}

sub get_atom_xml {
	my (%options) = @_;

	my $language = $options{language};
	my $featured = $options{featured};
	my $URL = $options{URL};
	my $appdir = $options{appdir};

        $language = '' if !defined $language;
        @$featured = grep {$_->{language} eq $language} @$featured if $language;
	my $ts = fix_ts($featured->[0]{featured});
	my $site_title = 'Perl TV Featured videos';

	my $xml = '';
	$xml .= qq{<?xml version="1.0" encoding="utf-8"?>\n};
	$xml .= qq{<feed xmlns="http://www.w3.org/2005/Atom">\n};
	$xml .= qq{<link href="$URL/$language/atom.xml" rel="self" />\n};
	$xml .= qq{<title>$site_title</title>\n};
	$xml .= qq{<id>$URL/</id>\n};
	$xml .= qq{<updated>$ts</updated>\n};
	foreach my $entry (@$featured) {

		my $data = read_file( "$appdir/data/videos/$entry->{path}" );
		my $title = $data->{title};
		$title =~ s/&/and/g;
		my $language = $languages{$data->{language}};

		$xml .= qq{<entry>\n};

		$xml .= qq{  <title>$title ($language $data->{length})</title>\n};
		$xml .= qq{  <summary type="html"><![CDATA[$data->{description}]]></summary>\n};
		my $ts = fix_ts($entry->{featured});
		$xml .= qq{  <updated>$ts</updated>\n};
		my $url = "$URL/v/$entry->{path}";
		$xml .= qq{  <link rel="alternate" type="text/html" href="$url" />};
		$xml .= qq{  <id>$URL/v/$entry->{path}</id>\n};
		$xml .= qq{  <content type="html"><![CDATA[$data->{description}]]></content>\n};
		$xml .= qq{  <author><name>$data->{speaker}</name></author>\n};
		$xml .= qq{</entry>\n};
	}
	$xml .= qq{</feed>\n};

	return $xml;
}
1;

