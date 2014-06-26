use strict;
use warnings;
use 5.010;

use Path::Tiny qw(path);

use lib path($0)->absolute->parent->parent->child('lib')->stringify;
use PerlTV::Fetch;

my ($url, $file) = @ARGV;

die "Usage: $0 URL [FILE]\n" if not $url;
my $fetch = PerlTV::Fetch->new;
$fetch->process($url, $file);

