#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use 5.010;

use Path::Tiny qw(path);

use lib path($0)->absolute->parent->parent->child('lib')->stringify;
use PerlTV::Import;


my $pi = PerlTV::Import->new;

$pi->import_people();
$pi->import_sources();
$pi->import_videos();
$pi->print_not_featured;

exit;

