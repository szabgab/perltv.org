#!/usr/bin/env perl
use strict;
use warnings;

use Path::Tiny qw(path);
use JSON::Tiny ();
use Data::Dumper qw(Dumper);

use lib path($0)->absolute->parent->parent->child('lib')->stringify;
use PerlTV::Tools qw(read_file);



my $dir = path($0)->absolute->parent->parent->child('data');
my @videos;
my @featured;
foreach my $f ($dir->children) {
	my $video = read_file($f);
	#warn Dumper $video;
	my %entry = (
		title => $video->{title},
		path  => $f->basename,
	);

	if ($video->{featured}) {
		push @featured, {
			id   => $video->{id},
			date => $video->{featured},
			path => $f->basename,
		}
	}

	push @videos, \%entry;
}

@featured = sort { $b->{date} cmp $a->{date} } @featured;

my $json = JSON::Tiny->new;
my %data = (
	_comment => 'This is a generated file, please do NOT edit directly',
	videos => \@videos,
);
path('videos.json')->spew_utf8( $json->encode(\%data) );
path('featured.json')->spew_utf8( $json->encode(\@featured) );

