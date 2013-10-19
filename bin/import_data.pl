#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Path::Tiny qw(path);
use JSON::Tiny ();
use Data::Dumper qw(Dumper);

use lib path($0)->absolute->parent->parent->child('lib')->stringify;
use PerlTV::Tools qw(read_file);



my $dir = path($0)->absolute->parent->parent->child('data/videos');
my @videos;
my @featured;
my %tags;
my %modules;
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
	if ($video->{tags}) {
		foreach my $tag (@{ $video->{tags} }) {
			push @{ $tags{lc $tag} }, \%entry;
		}
	}
	if ($video->{modules}) {
		foreach my $module (@{ $video->{modules} }) {
			push @{ $modules{$module} }, \%entry;
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
path('tags.json')->spew_utf8( $json->encode(\%tags) );
path('modules.json')->spew_utf8( $json->encode(\%modules) );

say "Latest featured: $featured[0]{date}";

