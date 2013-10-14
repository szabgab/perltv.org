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
foreach my $f ($dir->children) {
	my $video = read_file($f);
	#warn Dumper $video;
	my %entry = (
		title => $video->{title},
		path  => $f->basename,
	);

	push @videos, \%entry;
}

my $json = JSON::Tiny->new;
my %data = (
	_comment => 'This is a generated file, please do NOT edit directly',
	videos => \@videos,
);
path('videos.json')->spew_utf8(  $json->encode(\%data) );


